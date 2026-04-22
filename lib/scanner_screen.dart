// Código final

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart'; // <-- CÁMARA HD NATIVA
import 'dart:io';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  bool _isTorchOn = false; // Control manual de linterna
  
  // --- CONTROLADOR DEL ESCÁNER ---
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal, 
    detectionTimeoutMs: 300, 
    returnImage: false, // APAGADO: Máxima velocidad de video
    formats: const [
      BarcodeFormat.code128, 
      BarcodeFormat.code39,  
      BarcodeFormat.code93,  
      BarcodeFormat.ean13,   
      BarcodeFormat.itf,     
    ],
  );
  
  late AnimationController _animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- HERRAMIENTAS OCR HD ---
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  // REGEX ESTRICTOS. 
  final RegExp _rackRegex = RegExp(r'[A-Z]{2}-\d{2}-\d'); // Estricto para AA-06-2
  final RegExp _tinyLabelRegex = RegExp(r'000LP\s*-\s*\d{11}'); // Estricto para la etiqueta enana

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _scannerController.dispose();
    _audioPlayer.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  // --- NUEVO FLUJO  DE TEXTO ---
  Future<void> _takeHighResPhoto() async {
    HapticFeedback.heavyImpact();
    // 1. Pausamos el escáner verde para liberar la cámara
    await _scannerController.stop();

    try {
      // 2. Abrimos la cámara nativa del Cubot en Máxima Calidad
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (photo == null) {
        // Si el usuario cancela, volvemos a prender el escáner verde
        await _scannerController.start();
        return;
      }

      // 3. Procesamos la foto HD
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
      );

      final inputImage = InputImage.fromFilePath(photo.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (mounted) Navigator.pop(context); // Quitar el loading

      if (recognizedText.text.isEmpty) {
        _showErrorDialog("No se detectó ningún texto en la foto.");
        await _scannerController.start();
        return;
      }

      // 4. Búsqueda Inteligente en la foto HD
      String fullText = recognizedText.text.toUpperCase();
      
      // ¿Es la etiqueta LP?
      final tinyMatch = _tinyLabelRegex.firstMatch(fullText);
      if (tinyMatch != null) {
        _returnSuccess(tinyMatch.group(0)!.replaceAll(' ', '')); // Limpiamos espacios
        return;
      }

      // ¿Es un rack que el láser no pudo leer?
      final rackMatch = _rackRegex.firstMatch(fullText);
      if (rackMatch != null) {
        _returnSuccess(rackMatch.group(0)!);
        return;
      }

      // 5. SI NO COINCIDE EL FORMATO AUTOMÁTICO -> Mostramos las opciones al operador
      _showTextSelectionDialog(recognizedText.blocks);

    } catch (e) {
      if (mounted) Navigator.pop(context); // Asegurar quitar el loading
      _showErrorDialog("Error al procesar la imagen.");
      await _scannerController.start();
    }
  }

  Future<void> _returnSuccess(String validCode) async {
    _isScanned = true;
    HapticFeedback.heavyImpact();
    await _audioPlayer.play(AssetSource('audio/beepscan.mp3'));
    if (context.mounted) Navigator.pop(context, validCode);
  }

  // --- DIÁLOGO DE SELECCIÓN DE TEXTO ---
  void _showTextSelectionDialog(List<TextBlock> blocks) {
    // Filtramos bloques muy cortos que suelen ser basura
    List<String> validTexts = blocks
        .map((b) => b.text.toUpperCase().trim())
        .where((text) => text.length > 4) 
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Seleccione el texto correcto:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              validTexts.isEmpty
                ? const Text("Textos ilegibles.", style: TextStyle(color: Colors.redAccent))
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: validTexts.map((text) => ActionChip(
                      backgroundColor: Colors.grey.shade800,
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                      label: Text(text),
                      onPressed: () {
                        Navigator.pop(context); // Cierra el modal
                        _returnSuccess(text); // Devuelve el texto seleccionado a BD
                      },
                    )).toList(),
                  ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _scannerController.start(); // Reactivamos el láser
                },
                child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontSize: 16)),
              )
            ],
          ),
        );
      }
    );
  }

  void _showErrorDialog(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double scanAreaWidth = constraints.maxWidth * 0.75;
          final double scanAreaHeight = constraints.maxHeight * 0.35;
          final Rect scanWindow = Rect.fromCenter(
            center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
            width: scanAreaWidth,
            height: scanAreaHeight,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. ESCÁNER PURO DE CÓDIGOS DE BARRAS
              MobileScanner(
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (BarcodeCapture capture) async {
                  if (_isScanned) return;
                  for (final barcode in capture.barcodes) {
                    if (barcode.rawValue != null) {
                      _returnSuccess(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),

              Container(decoration: const ShapeDecoration(shape: ScannerOverlayShape())),

              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double laserY = (constraints.maxHeight - scanAreaHeight) / 2 + (scanAreaHeight * _animationController.value);
                  return Positioned(
                    top: laserY, left: (constraints.maxWidth - scanAreaWidth) / 2,
                    child: Container(
                      width: scanAreaWidth, height: 3.0,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.transparent, Color(0xFF00E676), Colors.transparent], stops: [0.0, 0.5, 1.0]),
                        boxShadow: [BoxShadow(color: const Color(0xFF00E676).withOpacity(0.6), blurRadius: 10, spreadRadius: 2)],
                      ),
                    ),
                  );
                },
              ),

              Positioned(
                top: 40, left: 20,
                child: _buildFloatingButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
              ),

              // CONTROLES ERGONÓMICOS
              Positioned(
                bottom: 120, right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // BOTÓN OCR (Abre la cámara nativa HD)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.8), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
                      child: IconButton(icon: const Icon(Icons.document_scanner_rounded, color: Colors.white), onPressed: _takeHighResPhoto),
                    ),
                    
                    // Botón de Linterna
                    Container(
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
                      child: IconButton(
                        icon: Icon(_isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded, color: _isTorchOn ? Colors.yellowAccent : Colors.white, size: 28),
                        onPressed: () {
                          setState(() => _isTorchOn = !_isTorchOn);
                          _scannerController.toggleTorch();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // INSTRUCCIÓN BASE
              Positioned(
                bottom: 40, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.center_focus_weak_rounded, color: Color(0xFF00E676), size: 20),
                        SizedBox(width: 10),
                        Text('Enfoque código, o use Escáner de Texto', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onTap, Color color = Colors.white}) {
    return Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)), child: IconButton(icon: Icon(icon, color: color, size: 28), onPressed: onTap));
  }
}

// --- RETÍCULA ---
class ScannerOverlayShape extends ShapeBorder {
  const ScannerOverlayShape();
  @override EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);
  @override Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()..fillType = PathFillType.evenOdd..addPath(getOuterPath(rect), Offset.zero);
  @override Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    return Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd;
  }
  @override void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    canvas.drawPath(Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd, Paint()..color = Colors.black.withOpacity(0.8)..style = PaintingStyle.fill);
    final borderPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 4.0..strokeCap = StrokeCap.square;
    final double cl = 35.0;
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(0, -cl), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(0, -cl), borderPaint);
    final crosshairPaint = Paint()..color = Colors.white.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    canvas.drawLine(rect.center - const Offset(10, 0), rect.center + const Offset(10, 0), crosshairPaint);
    canvas.drawLine(rect.center - const Offset(0, 10), rect.center + const Offset(0, 10), crosshairPaint);
  }
  @override ShapeBorder scale(double t) => this;
}