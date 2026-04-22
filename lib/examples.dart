/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la vibración
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  final MobileScannerController _scannerController = MobileScannerController();
  late AnimationController _animationController;

  // Reproductor de audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Configuración para poner la pantalla en modo inmersivo (oculta la barra de estado de Android)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ), // Movimiento rápido y fluido
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    // Restauramos la barra de estado de Android al salir
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
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
              // 1. Cámara base
              MobileScanner(
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (BarcodeCapture capture) async {
                  // <-- OJO: Agrega 'async' aquí
                  if (_isScanned) return;

                  for (final barcode in capture.barcodes) {
                    if (barcode.rawValue != null) {
                      _isScanned = true;

                      // --- MAGIA INDUSTRIAL 3.0 ---
                      HapticFeedback.heavyImpact(); // Vibración
                      await _audioPlayer.play(
                        AssetSource('audio/beepscan.mp3'),
                      ); // Tu Beep personalizado
                      // ----------------------------

                      if (context.mounted) {
                        Navigator.pop(context, barcode.rawValue!);
                      }
                      break;
                    }
                  }
                },
              ),

              // 2. Overlay oscuro con esquinas y mira central
              Container(
                decoration: const ShapeDecoration(shape: ScannerOverlayShape()),
              ),

              // 3. Láser de luz estilo Gradiente
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  // El láser se mueve dentro del área de escaneo
                  final double laserY =
                      (constraints.maxHeight - scanAreaHeight) / 2 +
                      (scanAreaHeight * _animationController.value);

                  return Positioned(
                    top: laserY,
                    left: (constraints.maxWidth - scanAreaWidth) / 2,
                    child: Container(
                      width: scanAreaWidth,
                      height: 3.0,
                      decoration: BoxDecoration(
                        // Degradado que desvanece las puntas del láser
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF00E676),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 4. Controles Flotantes Superiores (Estilo Inmersivo)
              Positioned(
                top: 40, // Margen superior seguro
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón de Cancelar / Atrás
                    _buildFloatingButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    // Botón de Linterna Dinámico
                    ValueListenableBuilder(
                      valueListenable: _scannerController,
                      builder: (context, state, child) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return _buildFloatingButton(
                          icon:
                              isTorchOn
                                  ? Icons.flashlight_on_rounded
                                  : Icons.flashlight_off_rounded,
                          color: isTorchOn ? Colors.yellowAccent : Colors.white,
                          onTap: () => _scannerController.toggleTorch(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 5. Texto de Instrucción Inferior
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.center_focus_weak_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Enfoque el código de barras',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
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

  // Widget reutilizable para los botones flotantes de cristal
  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5), // Fondo translúcido
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white24,
          width: 1,
        ), // Borde de cristal sutil
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 28),
        onPressed: onTap,
      ),
    );
  }
}

// --- PINTOR DE LA RETÍCULA ULTRA-PROFESIONAL ---
class ScannerOverlayShape extends ShapeBorder {
  const ScannerOverlayShape();

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.75,
      height: rect.height * 0.35,
    );
    return Path()
      ..addRect(rect)
      ..addRect(scanArea)
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.75,
      height: rect.height * 0.35,
    );

    // Fondo oscuro con mayor opacidad para resaltar el centro
    final backgroundPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    final backgroundPath =
        Path()
          ..addRect(rect)
          ..addRect(scanArea)
          ..fillType = PathFillType.evenOdd;
    canvas.drawPath(backgroundPath, backgroundPaint);

    // Bordes de esquina en color Blanco Puro (apariencia de cámara profesional)
    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.square;

    final double cornerLength = 35.0;

    // Dibujamos las 4 esquinas
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(0, cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(0, cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(0, -cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(0, -cornerLength),
      borderPaint,
    );

    // --- EL PUNTO DE MIRA (CROSSHAIR) ---
    // Una sutil cruz blanca semi-transparente en el centro exacto
    final crosshairPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final Offset center = rect.center;
    final double crosshairSize = 10.0; // Tamaño de la crucecita

    canvas.drawLine(
      center - Offset(crosshairSize, 0),
      center + Offset(crosshairSize, 0),
      crosshairPaint,
    );
    canvas.drawLine(
      center - Offset(0, crosshairSize),
      center + Offset(0, crosshairSize),
      crosshairPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}*/


// ======================================================
// ======================================================
// == ESCÁNER DE CÓDIGOS DE BARRAS ULTRA-PROFESIONAL PARA ALMACÉN ==
// == CON VIBRACIÓN, SONIDO PERSONALIZADO Y DISEÑO DE INTERFAZ INSPIRADO EN CÁMARAS PROFESIONALES DE INDUSTRIA 4.0 ==
// ======================================================



/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la vibración
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  
  // --- MAGIA INDUSTRIAL APLICADA AQUÍ ---
  // Restringimos el escáner a formatos de almacén para multiplicar la velocidad x10
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 300, // Tiempo de refresco ultrarrápido
    returnImage: false,
    formats: const [
      BarcodeFormat.code128, // Formato estándar numérico (el de abajo en tu foto)
      BarcodeFormat.code39,  // Formato clásico alfanumérico de racks (AA-06-2)
      BarcodeFormat.code93,  // Variante industrial
      BarcodeFormat.ean13,   // SKU de productos estándar
      BarcodeFormat.itf,     // Cajas corrugadas (Interleaved 2 of 5)
    ],
  );
  
  late AnimationController _animationController;

  // Reproductor de audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Configuración para poner la pantalla en modo inmersivo (oculta la barra de estado de Android)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ), // Movimiento rápido y fluido
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    // Restauramos la barra de estado de Android al salir
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
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
              // 1. Cámara base
              MobileScanner(
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (BarcodeCapture capture) async {
                  if (_isScanned) return;

                  for (final barcode in capture.barcodes) {
                    if (barcode.rawValue != null) {
                      _isScanned = true;

                      // --- FEEDBACK SENSORIAL ---
                      HapticFeedback.heavyImpact(); // Vibración
                      await _audioPlayer.play(
                        AssetSource('audio/beepscan.mp3'),
                      ); // Tu Beep personalizado

                      if (context.mounted) {
                        Navigator.pop(context, barcode.rawValue!);
                      }
                      break;
                    }
                  }
                },
              ),

              // 2. Overlay oscuro con esquinas y mira central
              Container(
                decoration: const ShapeDecoration(shape: ScannerOverlayShape()),
              ),

              // 3. Láser de luz estilo Gradiente
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  // El láser se mueve dentro del área de escaneo
                  final double laserY =
                      (constraints.maxHeight - scanAreaHeight) / 2 +
                      (scanAreaHeight * _animationController.value);

                  return Positioned(
                    top: laserY,
                    left: (constraints.maxWidth - scanAreaWidth) / 2,
                    child: Container(
                      width: scanAreaWidth,
                      height: 3.0,
                      decoration: BoxDecoration(
                        // Degradado que desvanece las puntas del láser
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF00E676),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 4. Controles Flotantes Superiores (Estilo Inmersivo)
              Positioned(
                top: 40, // Margen superior seguro
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón de Cancelar / Atrás
                    _buildFloatingButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    // Botón de Linterna Dinámico
                    ValueListenableBuilder(
                      valueListenable: _scannerController,
                      builder: (context, state, child) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return _buildFloatingButton(
                          icon:
                              isTorchOn
                                  ? Icons.flashlight_on_rounded
                                  : Icons.flashlight_off_rounded,
                          color: isTorchOn ? Colors.yellowAccent : Colors.white,
                          onTap: () => _scannerController.toggleTorch(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 5. Texto de Instrucción Inferior
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.center_focus_weak_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Enfoque el código de barras',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
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

  // Widget reutilizable para los botones flotantes de cristal
  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5), // Fondo translúcido
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white24,
          width: 1,
        ), // Borde de cristal sutil
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 28),
        onPressed: onTap,
      ),
    );
  }
}

// --- PINTOR DE LA RETÍCULA ULTRA-PROFESIONAL ---
class ScannerOverlayShape extends ShapeBorder {
  const ScannerOverlayShape();

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.75,
      height: rect.height * 0.35,
    );
    return Path()
      ..addRect(rect)
      ..addRect(scanArea)
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.75,
      height: rect.height * 0.35,
    );

    // Fondo oscuro con mayor opacidad para resaltar el centro
    final backgroundPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    final backgroundPath =
        Path()
          ..addRect(rect)
          ..addRect(scanArea)
          ..fillType = PathFillType.evenOdd;
    canvas.drawPath(backgroundPath, backgroundPaint);

    // Bordes de esquina en color Blanco Puro (apariencia de cámara profesional)
    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.square;

    final double cornerLength = 35.0;

    // Dibujamos las 4 esquinas
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(0, cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(0, cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(0, -cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(0, -cornerLength),
      borderPaint,
    );

    // --- EL PUNTO DE MIRA (CROSSHAIR) ---
    // Una sutil cruz blanca semi-transparente en el centro exacto
    final crosshairPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final Offset center = rect.center;
    final double crosshairSize = 10.0; // Tamaño de la crucecita

    canvas.drawLine(
      center - Offset(crosshairSize, 0),
      center + Offset(crosshairSize, 0),
      crosshairPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}




/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la vibración
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  
  // --- MAGIA INDUSTRIAL OPTIMIZADA ---
  final MobileScannerController _scannerController = MobileScannerController(
    // 1. MEJORA: Cambiamos a 'normal' para no retrasar el procesamiento. 
    // Tu variable _isScanned ya hace el trabajo de evitar duplicados.
    detectionSpeed: DetectionSpeed.normal, 
    detectionTimeoutMs: 300, // Tiempo de refresco ultrarrápido (Tu medida ideal)
    returnImage: false,
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

  // 2. MEJORA: Variable para controlar el Zoom
  double _currentZoom = 1.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ), 
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN DEL BOTÓN DE ZOOM ---
  void _toggleZoom() {
    setState(() {
      _currentZoom = _currentZoom == 1.0 ? 2.0 : 1.0;
      _scannerController.setZoomScale(_currentZoom);
      HapticFeedback.lightImpact(); // Pequeña vibración al hacer zoom
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // TU MEDIDA GANADORA INTACTA
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
              // 1. Cámara base
              MobileScanner(
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (BarcodeCapture capture) async {
                  if (_isScanned) return;

                  for (final barcode in capture.barcodes) {
                    if (barcode.rawValue != null) {
                      _isScanned = true;

                      // --- FEEDBACK SENSORIAL ---
                      HapticFeedback.heavyImpact(); 
                      await _audioPlayer.play(
                        AssetSource('audio/beepscan.mp3'),
                      ); 

                      if (context.mounted) {
                        Navigator.pop(context, barcode.rawValue!);
                      }
                      break;
                    }
                  }
                },
              ),

              // 2. Overlay oscuro con esquinas y mira central
              Container(
                decoration: const ShapeDecoration(shape: ScannerOverlayShape()),
              ),

              // 3. Láser de luz estilo Gradiente
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double laserY =
                      (constraints.maxHeight - scanAreaHeight) / 2 +
                      (scanAreaHeight * _animationController.value);

                  return Positioned(
                    top: laserY,
                    left: (constraints.maxWidth - scanAreaWidth) / 2,
                    child: Container(
                      width: scanAreaWidth,
                      height: 3.0,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF00E676),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 4. Controles Flotantes Superiores (Estilo Inmersivo)
              Positioned(
                top: 40, 
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón de Cancelar / Atrás
                    _buildFloatingButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    
                    Row(
                      children: [
                        // NUEVO BOTÓN DE ZOOM x2
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: _currentZoom > 1.0 
                                ? Colors.blueAccent.withOpacity(0.8) 
                                : Colors.black.withOpacity(0.5), 
                            shape: BoxShape.circle, 
                            border: Border.all(color: Colors.white24, width: 1)
                          ),
                          child: IconButton(
                            icon: Text(
                              '${_currentZoom.toInt()}x', 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                            onPressed: _toggleZoom,
                          ),
                        ),

                        // Botón de Linterna Dinámico
                        ValueListenableBuilder(
                          valueListenable: _scannerController,
                          builder: (context, state, child) {
                            final isTorchOn = state.torchState == TorchState.on;
                            return _buildFloatingButton(
                              icon:
                                  isTorchOn
                                      ? Icons.flashlight_on_rounded
                                      : Icons.flashlight_off_rounded,
                              color: isTorchOn ? Colors.yellowAccent : Colors.white,
                              onTap: () => _scannerController.toggleTorch(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 5. Texto de Instrucción Inferior
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.center_focus_weak_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Enfoque el código de barras',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
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

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5), 
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white24,
          width: 1,
        ), 
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 28),
        onPressed: onTap,
      ),
    );
  }
}

// --- TU PINTOR DE LA RETÍCULA INTACTO ---
class ScannerOverlayShape extends ShapeBorder {
  const ScannerOverlayShape();

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.75,
      height: rect.height * 0.35,
    );
    return Path()
      ..addRect(rect)
      ..addRect(scanArea)
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.75,
      height: rect.height * 0.35,
    );

    final backgroundPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    final backgroundPath =
        Path()
          ..addRect(rect)
          ..addRect(scanArea)
          ..fillType = PathFillType.evenOdd;
    canvas.drawPath(backgroundPath, backgroundPaint);

    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.square;

    final double cornerLength = 35.0;

    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(0, cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(0, cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(0, -cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(0, -cornerLength),
      borderPaint,
    );

    final crosshairPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final Offset center = rect.center;
    final double crosshairSize = 10.0; 

    canvas.drawLine(
      center - Offset(crosshairSize, 0),
      center + Offset(crosshairSize, 0),
      crosshairPaint,
    );
    canvas.drawLine(
      center - Offset(0, crosshairSize),
      center + Offset(0, crosshairSize),
      crosshairPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}*/






import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la vibración
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  bool _isZoomed = false; // Control Booleano del Zoom

  // --- MAGIA INDUSTRIAL APLICADA AQUÍ ---
  final MobileScannerController _scannerController = MobileScannerController(
    // Cambiado a 'normal' para no bloquear el motor, tu '_isScanned' ya evita duplicados
    detectionSpeed: DetectionSpeed.normal, 
    detectionTimeoutMs: 300, 
    returnImage: false,
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

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ), 
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _scannerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- FUNCIÓN DEL ZOOM CORREGIDA ---
  void _toggleZoom() {
    setState(() {
      _isZoomed = !_isZoomed;
      // 0.0 regresa a la normalidad, 0.5 da el acercamiento
      double targetZoom = _isZoomed ? 0.5 : 0.0;
      
      try {
        _scannerController.setZoomScale(targetZoom);
      } catch (e) {
        debugPrint("Error de Zoom");
      }
      HapticFeedback.lightImpact(); 
    });
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
              // 1. Cámara base
              MobileScanner(
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (BarcodeCapture capture) async {
                  if (_isScanned) return;

                  for (final barcode in capture.barcodes) {
                    if (barcode.rawValue != null) {
                      _isScanned = true;

                      // --- FEEDBACK SENSORIAL ---
                      HapticFeedback.heavyImpact(); 
                      await _audioPlayer.play(
                        AssetSource('audio/beepscan.mp3'),
                      ); 

                      if (context.mounted) {
                        Navigator.pop(context, barcode.rawValue!);
                      }
                      break;
                    }
                  }
                },
              ),

              // 2. Overlay oscuro con esquinas y mira central
              Container(
                decoration: const ShapeDecoration(shape: ScannerOverlayShape()),
              ),

              // 3. Láser de luz estilo Gradiente
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double laserY =
                      (constraints.maxHeight - scanAreaHeight) / 2 +
                      (scanAreaHeight * _animationController.value);

                  return Positioned(
                    top: laserY,
                    left: (constraints.maxWidth - scanAreaWidth) / 2,
                    child: Container(
                      width: scanAreaWidth,
                      height: 3.0,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF00E676),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 4. Controles Flotantes Superiores
              Positioned(
                top: 40, 
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón de Cancelar / Atrás
                    _buildFloatingButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    
                    Row(
                      children: [
                        // BOTÓN DE ZOOM x2
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: _isZoomed ? Colors.blueAccent.withOpacity(0.8) : Colors.black.withOpacity(0.5), 
                            shape: BoxShape.circle, 
                            border: Border.all(color: Colors.white24, width: 1)
                          ),
                          child: IconButton(
                            icon: Text(
                              _isZoomed ? '2x' : '1x', 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                            onPressed: _toggleZoom,
                          ),
                        ),

                        // Botón de Linterna
                        ValueListenableBuilder(
                          valueListenable: _scannerController,
                          builder: (context, state, child) {
                            final isTorchOn = state.torchState == TorchState.on;
                            return _buildFloatingButton(
                              icon:
                                  isTorchOn
                                      ? Icons.flashlight_on_rounded
                                      : Icons.flashlight_off_rounded,
                              color: isTorchOn ? Colors.yellowAccent : Colors.white,
                              onTap: () => _scannerController.toggleTorch(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 5. Texto de Instrucción Inferior
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.center_focus_weak_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Enfoque el código de barras',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
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

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5), 
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white24,
          width: 1,
        ), 
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 28),
        onPressed: onTap,
      ),
    );
  }
}

// --- PINTOR DE LA RETÍCULA ULTRA-PROFESIONAL ---
class ScannerOverlayShape extends ShapeBorder {
  const ScannerOverlayShape();

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.75,
      height: rect.height * 0.35,
    );
    return Path()
      ..addRect(rect)
      ..addRect(scanArea)
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.75,
      height: rect.height * 0.35,
    );

    final backgroundPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    final backgroundPath =
        Path()
          ..addRect(rect)
          ..addRect(scanArea)
          ..fillType = PathFillType.evenOdd;
    canvas.drawPath(backgroundPath, backgroundPaint);

    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.square;

    final double cornerLength = 35.0;

    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(0, cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(0, cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(0, -cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(0, -cornerLength),
      borderPaint,
    );

    final crosshairPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final Offset center = rect.center;
    final double crosshairSize = 10.0; 

    canvas.drawLine(
      center - Offset(crosshairSize, 0),
      center + Offset(crosshairSize, 0),
      crosshairPaint,
    );
    canvas.drawLine(
      center - Offset(0, crosshairSize),
      center + Offset(0, crosshairSize),
      crosshairPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}*/





//- --------------------------------------------------------
//- --------------------------------------------------------
// --- VERSIÓN SIN OCR INTEGRADO LECTURA RÁPIDA ------------


/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la vibración
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  bool _isZoomed = false; // Control Booleano del Zoom

  // --- MAGIA INDUSTRIAL APLICADA AQUÍ ---
  final MobileScannerController _scannerController = MobileScannerController(
    // Cambiado a 'normal' para no bloquear el motor, tu '_isScanned' ya evita duplicados
    detectionSpeed: DetectionSpeed.normal, 
    detectionTimeoutMs: 300, 
    returnImage: false,
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

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ), 
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _scannerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- FUNCIÓN DEL ZOOM CORREGIDA ---
  void _toggleZoom() {
    setState(() {
      _isZoomed = !_isZoomed;
      // 0.0 regresa a la normalidad, 0.5 da el acercamiento
      double targetZoom = _isZoomed ? 0.5 : 0.0;
      
      try {
        _scannerController.setZoomScale(targetZoom);
      } catch (e) {
        debugPrint("Error de Zoom");
      }
      HapticFeedback.lightImpact(); 
    });
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
              // 1. Cámara base
              MobileScanner(
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (BarcodeCapture capture) async {
                  if (_isScanned) return;

                  for (final barcode in capture.barcodes) {
                    if (barcode.rawValue != null) {
                      _isScanned = true;

                      // --- FEEDBACK SENSORIAL ---
                      HapticFeedback.heavyImpact(); 
                      await _audioPlayer.play(
                        AssetSource('audio/beepscan.mp3'),
                      ); 

                      if (context.mounted) {
                        Navigator.pop(context, barcode.rawValue!);
                      }
                      break;
                    }
                  }
                },
              ),

              // 2. Overlay oscuro con esquinas y mira central
              Container(
                decoration: const ShapeDecoration(shape: ScannerOverlayShape()),
              ),

              // 3. Láser de luz estilo Gradiente
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double laserY =
                      (constraints.maxHeight - scanAreaHeight) / 2 +
                      (scanAreaHeight * _animationController.value);

                  return Positioned(
                    top: laserY,
                    left: (constraints.maxWidth - scanAreaWidth) / 2,
                    child: Container(
                      width: scanAreaWidth,
                      height: 3.0,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF00E676),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 4. Controles Flotantes Superiores
              Positioned(
                top: 40, 
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón de Cancelar / Atrás
                    _buildFloatingButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    
                    Row(
                      children: [
                        // BOTÓN DE ZOOM x2
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: _isZoomed ? Colors.blueAccent.withOpacity(0.8) : Colors.black.withOpacity(0.5), 
                            shape: BoxShape.circle, 
                            border: Border.all(color: Colors.white24, width: 1)
                          ),
                          child: IconButton(
                            icon: Text(
                              _isZoomed ? '2x' : '1x', 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                            onPressed: _toggleZoom,
                          ),
                        ),

                        // Botón de Linterna
                        ValueListenableBuilder(
                          valueListenable: _scannerController,
                          builder: (context, state, child) {
                            final isTorchOn = state.torchState == TorchState.on;
                            return _buildFloatingButton(
                              icon:
                                  isTorchOn
                                      ? Icons.flashlight_on_rounded
                                      : Icons.flashlight_off_rounded,
                              color: isTorchOn ? Colors.yellowAccent : Colors.white,
                              onTap: () => _scannerController.toggleTorch(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 5. Texto de Instrucción Inferior
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.center_focus_weak_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Enfoque el código de barras',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
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

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5), 
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white24,
          width: 1,
        ), 
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 28),
        onPressed: onTap,
      ),
    );
  }
}

// --- PINTOR DE LA RETÍCULA ULTRA-PROFESIONAL ---
class ScannerOverlayShape extends ShapeBorder {
  const ScannerOverlayShape();

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.75,
      height: rect.height * 0.35,
    );
    return Path()
      ..addRect(rect)
      ..addRect(scanArea)
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.75,
      height: rect.height * 0.35,
    );

    final backgroundPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    final backgroundPath =
        Path()
          ..addRect(rect)
          ..addRect(scanArea)
          ..fillType = PathFillType.evenOdd;
    canvas.drawPath(backgroundPath, backgroundPaint);

    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.square;

    final double cornerLength = 35.0;

    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(0, cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(0, cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(0, -cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(0, -cornerLength),
      borderPaint,
    );

    final crosshairPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final Offset center = rect.center;
    final double crosshairSize = 10.0; 

    canvas.drawLine(
      center - Offset(crosshairSize, 0),
      center + Offset(crosshairSize, 0),
      crosshairPaint,
    );
    canvas.drawLine(
      center - Offset(0, crosshairSize),
      center + Offset(0, crosshairSize),
      crosshairPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}*/









//- --------------------------------------------------------
//- --------------------------------------------------------
// --- VERSIÓN CON OCR INTEGRADO (EXPERIMENTAL) ---



/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la vibración
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  bool _isZoomed = false; 

  // --- VARIABLES OCR ---
  bool _isOcrMode = false; 
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RegExp _locationRegex = RegExp(r'[A-Z]{2}[-\s]*\d{2}[-\s]*\d'); 
  String _lastOcrRead = "Buscando texto...";
  bool _isProcessingOcr = false; // Seguro Anti-Ahogo para el Cubot

  // --- CONTROLADOR ---
  MobileScannerController? _scannerController;
  late AnimationController _animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Inicializamos con el modo rápido (sin OCR)
    _initController(false);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _initController(bool isOcr) {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal, 
      detectionTimeoutMs: 300, 
      returnImage: isOcr, // Solo pide imagen si estamos en modo azul
      formats: const [
        BarcodeFormat.code128, 
        BarcodeFormat.code39,  
        BarcodeFormat.code93,  
        BarcodeFormat.ean13,   
        BarcodeFormat.itf,     
      ],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _scannerController?.dispose();
    _audioPlayer.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  void _toggleZoom() {
    setState(() {
      _isZoomed = !_isZoomed;
      double targetZoom = _isZoomed ? 0.5 : 0.0;
      try {
        _scannerController?.setZoomScale(targetZoom);
      } catch (e) {
        debugPrint("Error de Zoom");
      }
      HapticFeedback.lightImpact(); 
    });
  }

  // --- EL SWITCH CORREGIDO ---
  void _toggleOcrMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isOcrMode = !_isOcrMode;
      _lastOcrRead = "Apunte al texto...";
      
      // Destruimos el motor viejo y creamos uno nuevo limpio
      _scannerController?.dispose();
      _initController(_isOcrMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color activeLaserColor = _isOcrMode ? Colors.blueAccent : const Color(0xFF00E676);

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
              // 1. Cámara base (EL VALUEKEY ES EL SALVAVIDAS AQUÍ)
              MobileScanner(
                key: ValueKey(_isOcrMode), // Esto obliga a redibujar la cámara desde cero al cambiar de modo
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (BarcodeCapture capture) async {
                  if (_isScanned) return;

                  if (!_isOcrMode) {
                    // --- MODO NORMAL (VELOCIDAD MÁXIMA) ---
                    for (final barcode in capture.barcodes) {
                      if (barcode.rawValue != null) {
                        _isScanned = true;
                        HapticFeedback.heavyImpact(); 
                        await _audioPlayer.play(AssetSource('audio/beepscan.mp3')); 

                        if (context.mounted) {
                          Navigator.pop(context, barcode.rawValue!);
                        }
                        break;
                      }
                    }
                  } else {
                    // --- MODO OCR (SEGURO ANTI-AHOGO ACTIVADO) ---
                    if (capture.image == null || _isProcessingOcr) return;
                    _isProcessingOcr = true; // Bloqueamos para que no procese más hasta terminar esta
                    
                    try {
                      final tempDir = await getTemporaryDirectory();
                      final tempFile = File('${tempDir.path}/temp_ocr.jpg');
                      await tempFile.writeAsBytes(capture.image!); 

                      final inputImage = InputImage.fromFile(tempFile);
                      final recognizedText = await _textRecognizer.processImage(inputImage);

                      if (recognizedText.text.isNotEmpty && mounted) {
                        setState(() {
                          _lastOcrRead = recognizedText.text.replaceAll('\n', ' ').take(30);
                        });
                      }

                      for (TextBlock block in recognizedText.blocks) {
                        final match = _locationRegex.firstMatch(block.text);
                        if (match != null) {
                          _isScanned = true;
                          HapticFeedback.heavyImpact();
                          await _audioPlayer.play(AssetSource('audio/beepscan.mp3'));
                          
                          String validCode = match.group(0)!.replaceAll(' ', '-');

                          if (context.mounted) {
                            Navigator.pop(context, validCode);
                          }
                          return;
                        }
                      }
                    } catch (e) {
                      debugPrint("Error OCR");
                    } finally {
                      _isProcessingOcr = false; // Desbloqueamos para la siguiente foto
                    }
                  }
                },
              ),

              // 2. Overlay
              Container(
                decoration: ShapeDecoration(shape: ScannerOverlayShape(borderColor: activeLaserColor)),
              ),

              // 3. Láser
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double laserY =
                      (constraints.maxHeight - scanAreaHeight) / 2 +
                      (scanAreaHeight * _animationController.value);

                  return Positioned(
                    top: laserY,
                    left: (constraints.maxWidth - scanAreaWidth) / 2,
                    child: Container(
                      width: scanAreaWidth,
                      height: 3.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, activeLaserColor, Colors.transparent],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(color: activeLaserColor.withOpacity(0.6), blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 4. Controles Superiores
              Positioned(
                top: 40, 
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFloatingButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
                    Row(
                      children: [
                        // BOTÓN DE MODO TEXTO (OCR)
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: _isOcrMode ? Colors.blueAccent.withOpacity(0.8) : Colors.black.withOpacity(0.5), 
                            shape: BoxShape.circle, 
                            border: Border.all(color: Colors.white24, width: 1)
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.text_fields_rounded, color: Colors.white),
                            onPressed: _toggleOcrMode,
                          ),
                        ),

                        // BOTÓN DE ZOOM x2
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: _isZoomed ? activeLaserColor.withOpacity(0.8) : Colors.black.withOpacity(0.5), 
                            shape: BoxShape.circle, 
                            border: Border.all(color: Colors.white24, width: 1)
                          ),
                          child: IconButton(
                            icon: Text(
                              _isZoomed ? '2x' : '1x', 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                            onPressed: _toggleZoom,
                          ),
                        ),

                        // Linterna
                        ValueListenableBuilder(
                          valueListenable: _scannerController!,
                          builder: (context, state, child) {
                            final isTorchOn = state.torchState == TorchState.on;
                            return _buildFloatingButton(
                              icon: isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                              color: isTorchOn ? Colors.yellowAccent : Colors.white,
                              onTap: () => _scannerController?.toggleTorch(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 5. Textos Inferiores
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    if (_isOcrMode)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueAccent)
                        ),
                        child: Text(
                          _lastOcrRead,
                          style: const TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isOcrMode ? Icons.document_scanner : Icons.center_focus_weak_rounded,
                            color: activeLaserColor, 
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isOcrMode ? 'Apunte al texto (Ej: AA-06-2)' : 'Enfoque el código de barras',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onTap, Color color = Colors.white}) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
      child: IconButton(icon: Icon(icon, color: color, size: 28), onPressed: onTap),
    );
  }
}

// --- PINTOR DE LA RETÍCULA (INTACTO) ---
class ScannerOverlayShape extends ShapeBorder {
  final Color borderColor; 
  const ScannerOverlayShape({this.borderColor = Colors.white});

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..fillType = PathFillType.evenOdd..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    return Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.8)..style = PaintingStyle.fill;
    canvas.drawPath(Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd, backgroundPaint);

    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 4.0..strokeCap = StrokeCap.square;
    final double cl = 35.0;

    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(0, -cl), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(0, -cl), borderPaint);

    final crosshairPaint = Paint()..color = borderColor.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final Offset center = rect.center;
    final double cs = 10.0; 

    canvas.drawLine(center - Offset(cs, 0), center + Offset(cs, 0), crosshairPaint);
    canvas.drawLine(center - Offset(0, cs), center + Offset(0, cs), crosshairPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}

extension StringExtension on String {
  String take(int length) {
    if (this.length <= length) return this;
    return substring(0, length);
  }
}*/





// Versión OCR para lectura rápida sin validación de formato (solo para pruebas de velocidad, no recomendado para producción) LOCALIDAD AA-02-2
// El regex y la validación se han eliminado para maximizar la velocidad de lectura, pero esto puede resultar en lecturas erróneas o no deseadas.


/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la vibración
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  bool _isZoomed = false; 

  // --- VARIABLES OCR ---
  bool _isOcrMode = false; 
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RegExp _locationRegex = RegExp(r'[A-Z]{2}[-\s]*\d{2}[-\s]*\d'); 
  String _lastOcrRead = "Buscando texto...";
  bool _isProcessingOcr = false; // Seguro Anti-Ahogo

  // --- CONTROLADOR ---
  MobileScannerController? _scannerController;
  late AnimationController _animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Inicializamos con el modo rápido (sin OCR)
    _initController(false);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _initController(bool isOcr) {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal, 
      detectionTimeoutMs: 300, 
      returnImage: isOcr, 
      formats: const [
        BarcodeFormat.code128, 
        BarcodeFormat.code39,  
        BarcodeFormat.code93,  
        BarcodeFormat.ean13,   
        BarcodeFormat.itf,     
      ],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _scannerController?.dispose();
    _audioPlayer.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  void _toggleZoom() {
    setState(() {
      _isZoomed = !_isZoomed;
      double targetZoom = _isZoomed ? 0.5 : 0.0;
      try {
        _scannerController?.setZoomScale(targetZoom);
      } catch (e) {
        debugPrint("Error de Zoom");
      }
      HapticFeedback.lightImpact(); 
    });
  }

  void _toggleOcrMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isOcrMode = !_isOcrMode;
      _lastOcrRead = "Apunte al texto...";
      
      _scannerController?.dispose();
      _initController(_isOcrMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color activeLaserColor = _isOcrMode ? Colors.blueAccent : const Color(0xFF00E676);

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
              // 1. Cámara base
              MobileScanner(
                key: ValueKey(_isOcrMode), 
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (BarcodeCapture capture) async {
                  if (_isScanned) return;

                  if (!_isOcrMode) {
                    for (final barcode in capture.barcodes) {
                      if (barcode.rawValue != null) {
                        _isScanned = true;
                        HapticFeedback.heavyImpact(); 
                        await _audioPlayer.play(AssetSource('audio/beepscan.mp3')); 

                        if (context.mounted) {
                          Navigator.pop(context, barcode.rawValue!);
                        }
                        break;
                      }
                    }
                  } else {
                    if (capture.image == null || _isProcessingOcr) return;
                    _isProcessingOcr = true; 
                    
                    try {
                      final tempDir = await getTemporaryDirectory();
                      final tempFile = File('${tempDir.path}/temp_ocr.jpg');
                      await tempFile.writeAsBytes(capture.image!); 

                      final inputImage = InputImage.fromFile(tempFile);
                      final recognizedText = await _textRecognizer.processImage(inputImage);

                      if (recognizedText.text.isNotEmpty && mounted) {
                        setState(() {
                          _lastOcrRead = recognizedText.text.replaceAll('\n', ' ').take(30);
                        });
                      }

                      for (TextBlock block in recognizedText.blocks) {
                        final match = _locationRegex.firstMatch(block.text);
                        if (match != null) {
                          _isScanned = true;
                          HapticFeedback.heavyImpact();
                          await _audioPlayer.play(AssetSource('audio/beepscan.mp3'));
                          
                          String validCode = match.group(0)!.replaceAll(' ', '-');

                          if (context.mounted) {
                            Navigator.pop(context, validCode);
                          }
                          return;
                        }
                      }
                    } catch (e) {
                      debugPrint("Error OCR");
                    } finally {
                      _isProcessingOcr = false; 
                    }
                  }
                },
              ),

              // 2. Overlay
              Container(
                decoration: ShapeDecoration(shape: ScannerOverlayShape(borderColor: activeLaserColor)),
              ),

              // 3. Láser
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double laserY =
                      (constraints.maxHeight - scanAreaHeight) / 2 +
                      (scanAreaHeight * _animationController.value);

                  return Positioned(
                    top: laserY,
                    left: (constraints.maxWidth - scanAreaWidth) / 2,
                    child: Container(
                      width: scanAreaWidth,
                      height: 3.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, activeLaserColor, Colors.transparent],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(color: activeLaserColor.withOpacity(0.6), blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 4. Botón de Cerrar (Mantenido arriba a la izquierda)
              Positioned(
                top: 40, 
                left: 20,
                child: _buildFloatingButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),

              // 5. Controles de Operación (Abajo a la Derecha, en línea vertical)
              Positioned(
                bottom: 95, // Ajustado para estar encima de las instrucciones
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // BOTÓN DE ZOOM x2
                    Container(
                      margin: const EdgeInsets.only(bottom: 16), // Espaciado hacia abajo
                      decoration: BoxDecoration(
                        color: _isZoomed ? activeLaserColor.withOpacity(0.8) : Colors.black.withOpacity(0.5), 
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.white24, width: 1)
                      ),
                      child: IconButton(
                        icon: Text(
                          _isZoomed ? '2x' : '1x', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        onPressed: _toggleZoom,
                      ),
                    ),

                    // BOTÓN DE MODO TEXTO (OCR)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16), // Espaciado hacia abajo
                      decoration: BoxDecoration(
                        color: _isOcrMode ? Colors.blueAccent.withOpacity(0.8) : Colors.black.withOpacity(0.5), 
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.white24, width: 1)
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.text_fields_rounded, color: Colors.white),
                        onPressed: _toggleOcrMode,
                      ),
                    ),

                    // Botón de Linterna
                    ValueListenableBuilder(
                      valueListenable: _scannerController!,
                      builder: (context, state, child) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return _buildFloatingButton(
                          icon: isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                          color: isTorchOn ? Colors.yellowAccent : Colors.white,
                          onTap: () => _scannerController?.toggleTorch(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 6. Textos Inferiores (Instrucciones)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    if (_isOcrMode)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueAccent)
                        ),
                        child: Text(
                          _lastOcrRead,
                          style: const TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isOcrMode ? Icons.document_scanner : Icons.center_focus_weak_rounded,
                            color: activeLaserColor, 
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isOcrMode ? 'Apunte al texto (Ej: AA-06-2)' : 'Enfoque el código de barras',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onTap, Color color = Colors.white}) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
      child: IconButton(icon: Icon(icon, color: color, size: 28), onPressed: onTap),
    );
  }
}

// --- PINTOR DE LA RETÍCULA ---
class ScannerOverlayShape extends ShapeBorder {
  final Color borderColor; 
  const ScannerOverlayShape({this.borderColor = Colors.white});

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..fillType = PathFillType.evenOdd..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    return Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.8)..style = PaintingStyle.fill;
    canvas.drawPath(Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd, backgroundPaint);

    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 4.0..strokeCap = StrokeCap.square;
    final double cl = 35.0;

    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(0, -cl), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(0, -cl), borderPaint);

    final crosshairPaint = Paint()..color = borderColor.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final Offset center = rect.center;
    final double cs = 10.0; 

    canvas.drawLine(center - Offset(cs, 0), center + Offset(cs, 0), crosshairPaint);
    canvas.drawLine(center - Offset(0, cs), center + Offset(0, cs), crosshairPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}

extension StringExtension on String {
  String take(int length) {
    if (this.length <= length) return this;
    return substring(0, length);
  }
}*/


//===== ANTES DE REFACTORIZAR PARA SOPORTAR ETIQUETAS DENSAS (CON LETRAS Y NÚMEROS) =====
// ======= ELIMINADO PORQUE EL CÓDIGAZO DE ARRIBA YA INCLUYE TODO LO QUE TENÍA ESTE, PERO CON UN REGEX MEJORADO PARA SOPORTAR MÁS FORMATOS DE ETIQUETAS =======


/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la vibración
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  bool _isZoomed = false; 

  // --- VARIABLES OCR ---
  bool _isOcrMode = false; 
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  // --- EL NUEVO REGEX MULTI-FORMATO ---
  // Atrapa: Racks normales (AA-06-2) O Etiquetas densas (000LP - 00899692010)
  //final RegExp _multiFormatRegex = RegExp(r'([A-Z]{2}[-\s]*\d{2}[-\s]*\d)|(\d{3}[A-Z]{2}[-\s]*\d{11})'); 
  // --- EL NUEVO REGEX MULTI-FORMATO ---
  // Racks (AA-06-2) O Etiquetas tolerando que confunda letras con números
  final RegExp _multiFormatRegex = RegExp(r'([A-Z]{2}[-\s]*\d{2}[-\s]*\d)|([A-Z0-9]{5}[-\s]*[A-Z0-9]{11})');
  
  String _lastOcrRead = "Buscando texto...";
  bool _isProcessingOcr = false; // Seguro Anti-Ahogo

  // --- CONTROLADOR ---
  MobileScannerController? _scannerController;
  late AnimationController _animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Inicializamos con el modo rápido (sin OCR)
    _initController(false);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _initController(bool isOcr) {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal, 
      detectionTimeoutMs: 300, 
      returnImage: isOcr, 
      formats: const [
        BarcodeFormat.code128, 
        BarcodeFormat.code39,  
        BarcodeFormat.code93,  
        BarcodeFormat.ean13,   
        BarcodeFormat.itf,     
      ],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _scannerController?.dispose();
    _audioPlayer.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  void _toggleZoom() {
    setState(() {
      _isZoomed = !_isZoomed;
      double targetZoom = _isZoomed ? 0.6 : 0.0; // Subimos un poco el zoom manual a 0.6
      try {
        _scannerController?.setZoomScale(targetZoom);
      } catch (e) {
        debugPrint("Error de Zoom");
      }
      HapticFeedback.lightImpact(); 
    });
  }

  void _toggleOcrMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isOcrMode = !_isOcrMode;
      _lastOcrRead = "Apunte al texto...";
      
      _scannerController?.dispose();
      _initController(_isOcrMode);

      // --- MODO LUPA AUTOMÁTICO PARA ETIQUETAS PEQUEÑAS ---
      // Le damos 500ms a la cámara para iniciar, y luego le metemos zoom si estamos en OCR
      Future.delayed(const Duration(milliseconds: 500), () {
         try {
           double autoZoom = _isOcrMode ? 0.6 : 0.0; // 0.6 es un acercamiento bastante agresivo
           _scannerController?.setZoomScale(autoZoom);
           if (mounted) {
             setState(() { _isZoomed = _isOcrMode; }); // Sincronizamos el botoncito 1x/2x
           }
         } catch (e) {
           debugPrint("Error forzando zoom: $e");
         }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color activeLaserColor = _isOcrMode ? Colors.blueAccent : const Color(0xFF00E676);

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
              // 1. Cámara base
              MobileScanner(
                key: ValueKey(_isOcrMode), 
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (BarcodeCapture capture) async {
                  if (_isScanned) return;

                  if (!_isOcrMode) {
                    for (final barcode in capture.barcodes) {
                      if (barcode.rawValue != null) {
                        _isScanned = true;
                        HapticFeedback.heavyImpact(); 
                        await _audioPlayer.play(AssetSource('audio/beepscan.mp3')); 

                        if (context.mounted) {
                          Navigator.pop(context, barcode.rawValue!);
                        }
                        break;
                      }
                    }
                  } else {
                    if (capture.image == null || _isProcessingOcr) return;
                    _isProcessingOcr = true; 
                    
                    try {
                      final tempDir = await getTemporaryDirectory();
                      final tempFile = File('${tempDir.path}/temp_ocr.jpg');
                      await tempFile.writeAsBytes(capture.image!); 

                      final inputImage = InputImage.fromFile(tempFile);
                      final recognizedText = await _textRecognizer.processImage(inputImage);

                      if (recognizedText.text.isNotEmpty && mounted) {
                        setState(() {
                          _lastOcrRead = recognizedText.text.replaceAll('\n', ' ').take(30);
                        });
                      }


                      for (TextBlock block in recognizedText.blocks) {
                        final match = _multiFormatRegex.firstMatch(block.text);
                        
                        if (match != null) {
                          _isScanned = true;
                          HapticFeedback.heavyImpact();
                          await _audioPlayer.play(AssetSource('audio/beepscan.mp3'));
                          
                          // 1. Obtenemos lo que leyó y lo pasamos a mayúsculas
                          String validCode = match.group(0)!.toUpperCase();

                          // 2. ¿Es la etiqueta enana de 16 caracteres? (000LP - ...)
                          if (validCode.replaceAll(RegExp(r'[-\s]'), '').length > 10) {
                            // Limpiamos todos los espacios y guiones basura
                            validCode = validCode.replaceAll(RegExp(r'[-\s]'), '');
                            
                            // EL TRUCO MAGICO: Cambiamos todas las letras 'O' por ceros '0'
                            validCode = validCode.replaceAll('O', '0');
                            
                            // Le inyectamos su guion oficial en medio para que tu BD lo acepte
                            validCode = '${validCode.substring(0, 5)}-${validCode.substring(5)}';
                          } else {
                            // 3. Es un Rack normal (AA-06-2)
                            validCode = validCode.replaceAll(RegExp(r'\s+-\s+'), '-').replaceAll(' ', '');
                          }

                          if (context.mounted) {
                            Navigator.pop(context, validCode);
                          }
                          return;
                        }
                      }

                      /*for (TextBlock block in recognizedText.blocks) {
                        // AQUÍ USAMOS EL NUEVO REGEX MULTI-FORMATO
                        final match = _multiFormatRegex.firstMatch(block.text);
                        
                        if (match != null) {
                          _isScanned = true;
                          HapticFeedback.heavyImpact();
                          await _audioPlayer.play(AssetSource('audio/beepscan.mp3'));
                          
                          // Limpiamos los espacios extras alrededor de los guiones para dejarlo limpio en tu BD
                          String validCode = match.group(0)!.replaceAll(RegExp(r'\s+-\s+'), '-').replaceAll(' ', '');

                          if (context.mounted) {
                            Navigator.pop(context, validCode);
                          }
                          return;
                        }
                      }*/
                    } catch (e) {
                      debugPrint("Error OCR");
                    } finally {
                      _isProcessingOcr = false; 
                    }
                  }
                },
              ),

              // 2. Overlay
              Container(
                decoration: ShapeDecoration(shape: ScannerOverlayShape(borderColor: activeLaserColor)),
              ),

              // 3. Láser
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double laserY =
                      (constraints.maxHeight - scanAreaHeight) / 2 +
                      (scanAreaHeight * _animationController.value);

                  return Positioned(
                    top: laserY,
                    left: (constraints.maxWidth - scanAreaWidth) / 2,
                    child: Container(
                      width: scanAreaWidth,
                      height: 3.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, activeLaserColor, Colors.transparent],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(color: activeLaserColor.withOpacity(0.6), blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 4. Botón de Cerrar (Izquierda Superior)
              Positioned(
                top: 40, 
                left: 20,
                child: _buildFloatingButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),

              // 5. Controles de Operación Ergonómicos (Abajo a la Derecha)
              Positioned(
                bottom: 95, 
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // BOTÓN DE ZOOM
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _isZoomed ? activeLaserColor.withOpacity(0.8) : Colors.black.withOpacity(0.5), 
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.white24, width: 1)
                      ),
                      child: IconButton(
                        icon: Text(
                          _isZoomed ? '2x' : '1x', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        onPressed: _toggleZoom,
                      ),
                    ),

                    // BOTÓN DE MODO TEXTO (OCR)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _isOcrMode ? Colors.blueAccent.withOpacity(0.8) : Colors.black.withOpacity(0.5), 
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.white24, width: 1)
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.text_fields_rounded, color: Colors.white),
                        onPressed: _toggleOcrMode,
                      ),
                    ),

                    // Botón de Linterna
                    ValueListenableBuilder(
                      valueListenable: _scannerController!,
                      builder: (context, state, child) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return _buildFloatingButton(
                          icon: isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                          color: isTorchOn ? Colors.yellowAccent : Colors.white,
                          onTap: () => _scannerController?.toggleTorch(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 6. Textos Inferiores e Instrucciones
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    if (_isOcrMode)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueAccent)
                        ),
                        child: Text(
                          _lastOcrRead,
                          style: const TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isOcrMode ? Icons.document_scanner : Icons.center_focus_weak_rounded,
                            color: activeLaserColor, 
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isOcrMode ? 'Aleje la etiqueta y enfoque' : 'Enfoque el código de barras',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onTap, Color color = Colors.white}) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
      child: IconButton(icon: Icon(icon, color: color, size: 28), onPressed: onTap),
    );
  }
}

// --- PINTOR DE LA RETÍCULA ---
class ScannerOverlayShape extends ShapeBorder {
  final Color borderColor; 
  const ScannerOverlayShape({this.borderColor = Colors.white});

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..fillType = PathFillType.evenOdd..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    return Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.8)..style = PaintingStyle.fill;
    canvas.drawPath(Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd, backgroundPaint);

    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 4.0..strokeCap = StrokeCap.square;
    final double cl = 35.0;

    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(0, -cl), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(0, -cl), borderPaint);

    final crosshairPaint = Paint()..color = borderColor.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final Offset center = rect.center;
    final double cs = 10.0; 

    canvas.drawLine(center - Offset(cs, 0), center + Offset(cs, 0), crosshairPaint);
    canvas.drawLine(center - Offset(0, cs), center + Offset(0, cs), crosshairPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}

extension StringExtension on String {
  String take(int length) {
    if (this.length <= length) return this;
    return substring(0, length);
  }
}*/









//================ VERSIÓN 2.0 CON OCR MEJORADO Y REGEX MULTI-FORMATO =================
// Esta versión mantiene la funcionalidad de escaneo rápido, pero al activar el modo OCR, ahora puede detectar tanto los racks normales (AA-06-2) como las etiquetas densas (000LP - 00899692010) gracias a un nuevo regex más flexible. Además, se implementó un zoom automático al activar el OCR para facilitar la lectura de etiquetas pequeñas, y se mejoraron las instrucciones en pantalla para guiar al usuario. La vibración y el sonido de confirmación siguen presentes para una experiencia táctil y auditiva completa.

/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la vibración
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  bool _isZoomed = false; 

  // --- VARIABLES OCR ---
  bool _isOcrMode = false; 
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  // Ya no necesitamos un Regex complejo arriba, lo haremos dinámico abajo
  String _lastOcrRead = "Buscando texto...";
  bool _isProcessingOcr = false; // Seguro Anti-Ahogo

  // --- CONTROLADOR ---
  MobileScannerController? _scannerController;
  late AnimationController _animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Inicializamos con el modo rápido (sin OCR)
    _initController(false);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _initController(bool isOcr) {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal, 
      detectionTimeoutMs: 300, 
      returnImage: isOcr, 
      formats: const [
        BarcodeFormat.code128, 
        BarcodeFormat.code39,  
        BarcodeFormat.code93,  
        BarcodeFormat.ean13,   
        BarcodeFormat.itf,     
      ],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _scannerController?.dispose();
    _audioPlayer.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  void _toggleZoom() {
    setState(() {
      _isZoomed = !_isZoomed;
      double targetZoom = _isZoomed ? 0.6 : 0.0;
      try {
        _scannerController?.setZoomScale(targetZoom);
      } catch (e) {
        debugPrint("Error de Zoom");
      }
      HapticFeedback.lightImpact(); 
    });
  }

  void _toggleOcrMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isOcrMode = !_isOcrMode;
      _lastOcrRead = "Apunte al texto...";
      
      _scannerController?.dispose();
      _initController(_isOcrMode);

      Future.delayed(const Duration(milliseconds: 500), () {
         try {
           double autoZoom = _isOcrMode ? 0.6 : 0.0; 
           _scannerController?.setZoomScale(autoZoom);
           if (mounted) {
             setState(() { _isZoomed = _isOcrMode; }); 
           }
         } catch (e) {
           debugPrint("Error forzando zoom");
         }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color activeLaserColor = _isOcrMode ? Colors.blueAccent : const Color(0xFF00E676);

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
              // 1. Cámara base
              MobileScanner(
                key: ValueKey(_isOcrMode), 
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (BarcodeCapture capture) async {
                  if (_isScanned) return;

                  if (!_isOcrMode) {
                    for (final barcode in capture.barcodes) {
                      if (barcode.rawValue != null) {
                        _isScanned = true;
                        HapticFeedback.heavyImpact(); 
                        await _audioPlayer.play(AssetSource('audio/beepscan.mp3')); 

                        if (context.mounted) {
                          Navigator.pop(context, barcode.rawValue!);
                        }
                        break;
                      }
                    }
                  } else {
                    if (capture.image == null || _isProcessingOcr) return;
                    _isProcessingOcr = true; 
                    
                    try {
                      final tempDir = await getTemporaryDirectory();
                      final tempFile = File('${tempDir.path}/temp_ocr.jpg');
                      await tempFile.writeAsBytes(capture.image!); 

                      final inputImage = InputImage.fromFile(tempFile);
                      final recognizedText = await _textRecognizer.processImage(inputImage);

                      String everything = recognizedText.text.toUpperCase();

                      if (everything.isNotEmpty && mounted) {
                        setState(() {
                          _lastOcrRead = everything.replaceAll('\n', ' ').take(30);
                        });
                      }

                      // --- ESTRATEGIA 1: BUSCAR RACK NORMAL (AA-06-2) ---
                      final rackMatch = RegExp(r'[A-Z]{2}[-\s]*\d{2}[-\s]*\d').firstMatch(everything);
                      if (rackMatch != null) {
                        _isScanned = true;
                        HapticFeedback.heavyImpact();
                        await _audioPlayer.play(AssetSource('audio/beepscan.mp3'));
                        
                        String validCode = rackMatch.group(0)!.replaceAll(RegExp(r'\s+-\s+'), '-').replaceAll(' ', '');
                        if (context.mounted) Navigator.pop(context, validCode);
                        return;
                      }

                      // --- ESTRATEGIA 2: LA LICUADORA PARA LA ETIQUETA REBELDE (000LP) ---
                      // 1. Quitamos TODO lo que no sea letra o número, y convertimos la 'O' en '0'
                      String denseText = everything.replaceAll(RegExp(r'[^A-Z0-9]'), '').replaceAll('O', '0');
                      
                      // 2. Buscamos exactamente 5 caracteres alfanuméricos seguidos de 11 números
                      // (Esto encaja perfecto con 000LP00899692010 sin importar si había saltos de línea)
                      final denseMatch = RegExp(r'[0-9A-Z]{5}\d{11}').firstMatch(denseText);
                      
                      if (denseMatch != null) {
                        _isScanned = true;
                        HapticFeedback.heavyImpact();
                        await _audioPlayer.play(AssetSource('audio/beepscan.mp3'));
                        
                        // Reconstruimos el código poniéndole su guion donde va
                        String rawCode = denseMatch.group(0)!;
                        String validCode = '${rawCode.substring(0, 5)}-${rawCode.substring(5)}';

                        if (context.mounted) Navigator.pop(context, validCode);
                        return;
                      }

                    } catch (e) {
                      debugPrint("Error OCR");
                    } finally {
                      _isProcessingOcr = false; 
                    }
                  }
                },
              ),

              // 2. Overlay
              Container(
                decoration: ShapeDecoration(shape: ScannerOverlayShape(borderColor: activeLaserColor)),
              ),

              // 3. Láser
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double laserY =
                      (constraints.maxHeight - scanAreaHeight) / 2 +
                      (scanAreaHeight * _animationController.value);

                  return Positioned(
                    top: laserY,
                    left: (constraints.maxWidth - scanAreaWidth) / 2,
                    child: Container(
                      width: scanAreaWidth,
                      height: 3.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, activeLaserColor, Colors.transparent],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(color: activeLaserColor.withOpacity(0.6), blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 4. Botón de Cerrar
              Positioned(
                top: 40, 
                left: 20,
                child: _buildFloatingButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),

              // 5. Controles de Operación
              Positioned(
                bottom: 95, 
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _isZoomed ? activeLaserColor.withOpacity(0.8) : Colors.black.withOpacity(0.5), 
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.white24, width: 1)
                      ),
                      child: IconButton(
                        icon: Text(
                          _isZoomed ? '2x' : '1x', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        onPressed: _toggleZoom,
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _isOcrMode ? Colors.blueAccent.withOpacity(0.8) : Colors.black.withOpacity(0.5), 
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.white24, width: 1)
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.text_fields_rounded, color: Colors.white),
                        onPressed: _toggleOcrMode,
                      ),
                    ),

                    ValueListenableBuilder(
                      valueListenable: _scannerController!,
                      builder: (context, state, child) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return _buildFloatingButton(
                          icon: isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                          color: isTorchOn ? Colors.yellowAccent : Colors.white,
                          onTap: () => _scannerController?.toggleTorch(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 6. Textos Inferiores e Instrucciones
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    if (_isOcrMode)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueAccent)
                        ),
                        child: Text(
                          _lastOcrRead,
                          style: const TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isOcrMode ? Icons.document_scanner : Icons.center_focus_weak_rounded,
                            color: activeLaserColor, 
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isOcrMode ? 'Aleje la etiqueta y enfoque' : 'Enfoque el código de barras',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onTap, Color color = Colors.white}) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
      child: IconButton(icon: Icon(icon, color: color, size: 28), onPressed: onTap),
    );
  }
}

// --- PINTOR DE LA RETÍCULA ---
class ScannerOverlayShape extends ShapeBorder {
  final Color borderColor; 
  const ScannerOverlayShape({this.borderColor = Colors.white});

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..fillType = PathFillType.evenOdd..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    return Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.8)..style = PaintingStyle.fill;
    canvas.drawPath(Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd, backgroundPaint);

    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 4.0..strokeCap = StrokeCap.square;
    final double cl = 35.0;

    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(0, -cl), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(0, -cl), borderPaint);

    final crosshairPaint = Paint()..color = borderColor.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final Offset center = rect.center;
    final double cs = 10.0; 

    canvas.drawLine(center - Offset(cs, 0), center + Offset(cs, 0), crosshairPaint);
    canvas.drawLine(center - Offset(0, cs), center + Offset(0, cs), crosshairPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}

extension StringExtension on String {
  String take(int length) {
    if (this.length <= length) return this;
    return substring(0, length);
  }
}*/




// ================ VERSIÓN 2.0 CON OCR MEJORADO Y REGEX MULTI-FORMATO =================
// Esta versión mantiene la funcionalidad de escaneo rápido, pero al activar el modo OCR, ahora puede detectar tanto los racks normales (AA-06-2) como las etiquetas densas (000LP - 00899692010) gracias a un nuevo regex más flexible. Además, se implementó un zoom automático al activar el OCR para facilitar la lectura de etiquetas pequeñas, y se mejoraron las instrucciones en pantalla para guiar al usuario. La vibración y el sonido de confirmación siguen presentes para una experiencia táctil y auditiva completa.

/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image/image.dart' as img; // <--- EL QUIROPRÁCTICO DE IMÁGENES

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  bool _isZoomed = false; 

  // --- VARIABLES OCR ---
  bool _isOcrMode = false; 
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RegExp _multiFormatRegex = RegExp(r'([A-Z]{2}[-\s]*\d{2}[-\s]*\d)|([A-Z0-9]{5}[-\s]*[A-Z0-9]{11})'); 
  
  String _lastOcrRead = "Buscando texto...";
  bool _isProcessingOcr = false; 

  // --- CONTROLADOR ---
  MobileScannerController? _scannerController;
  late AnimationController _animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initController(false);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _initController(bool isOcr) {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal, 
      detectionTimeoutMs: 300, 
      returnImage: isOcr, 
      formats: const [
        BarcodeFormat.code128, 
        BarcodeFormat.code39,  
        BarcodeFormat.code93,  
        BarcodeFormat.ean13,   
        BarcodeFormat.itf,     
      ],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _scannerController?.dispose();
    _audioPlayer.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  void _toggleZoom() {
    setState(() {
      _isZoomed = !_isZoomed;
      double targetZoom = _isZoomed ? 0.6 : 0.0;
      try {
        _scannerController?.setZoomScale(targetZoom);
      } catch (e) {
        debugPrint("Error de Zoom");
      }
      HapticFeedback.lightImpact(); 
    });
  }

  void _toggleOcrMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isOcrMode = !_isOcrMode;
      _lastOcrRead = "Apunte al texto...";
      
      _scannerController?.dispose();
      _initController(_isOcrMode);

      Future.delayed(const Duration(milliseconds: 500), () {
         try {
           double autoZoom = _isOcrMode ? 0.6 : 0.0; 
           _scannerController?.setZoomScale(autoZoom);
           if (mounted) setState(() { _isZoomed = _isOcrMode; }); 
         } catch (e) {}
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color activeLaserColor = _isOcrMode ? Colors.blueAccent : const Color(0xFF00E676);

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
              MobileScanner(
                key: ValueKey(_isOcrMode), 
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (BarcodeCapture capture) async {
                  if (_isScanned) return;

                  if (!_isOcrMode) {
                    for (final barcode in capture.barcodes) {
                      if (barcode.rawValue != null) {
                        _isScanned = true;
                        HapticFeedback.heavyImpact(); 
                        await _audioPlayer.play(AssetSource('audio/beepscan.mp3')); 
                        if (context.mounted) Navigator.pop(context, barcode.rawValue!);
                        break;
                      }
                    }
                  } else {
                    if (capture.image == null || _isProcessingOcr) return;
                    _isProcessingOcr = true; 
                    
                    try {
                      if (mounted) setState(() => _lastOcrRead = "Alineando imagen...");

                      final tempDir = await getTemporaryDirectory();
                      final tempFile = File('${tempDir.path}/temp_ocr.jpg');
                      
                      // --- LA MAGIA: ROTACIÓN FÍSICA ---
                      // 1. Decodificamos la imagen cruda
                      img.Image? capturedImage = img.decodeImage(capture.image!);
                      
                      if (capturedImage != null) {
                        // 2. La rotamos 90 grados a la derecha para ponerla vertical
                        img.Image fixedImage = img.copyRotate(capturedImage, angle: 90);
                        // 3. La guardamos ya enderezada
                        await tempFile.writeAsBytes(img.encodeJpg(fixedImage));
                      } else {
                        // Fallback por si acaso
                        await tempFile.writeAsBytes(capture.image!); 
                      }
                      // ----------------------------------

                      final inputImage = InputImage.fromFile(tempFile);
                      final recognizedText = await _textRecognizer.processImage(inputImage);
                      String everything = recognizedText.text.toUpperCase();

                      if (everything.isNotEmpty && mounted) {
                        setState(() {
                          _lastOcrRead = everything.replaceAll('\n', ' ').take(35);
                        });
                      }

                      // ESTRATEGIA 1: RACK (AA-06-2)
                      final rackMatch = RegExp(r'[A-Z]{2}[-\s]*\d{2}[-\s]*\d').firstMatch(everything);
                      if (rackMatch != null) {
                        _isScanned = true;
                        HapticFeedback.heavyImpact();
                        await _audioPlayer.play(AssetSource('audio/beepscan.mp3'));
                        String validCode = rackMatch.group(0)!.replaceAll(RegExp(r'\s+-\s+'), '-').replaceAll(' ', '');
                        if (context.mounted) Navigator.pop(context, validCode);
                        return;
                      }

                      // ESTRATEGIA 2: ETIQUETA ENANA (000LP00899692010)
                      String denseText = everything.replaceAll(RegExp(r'[^A-Z0-9]'), '').replaceAll('O', '0');
                      final denseMatch = RegExp(r'[0-9A-Z]{5}\d{11}').firstMatch(denseText);
                      
                      if (denseMatch != null) {
                        _isScanned = true;
                        HapticFeedback.heavyImpact();
                        await _audioPlayer.play(AssetSource('audio/beepscan.mp3'));
                        String rawCode = denseMatch.group(0)!;
                        String validCode = '${rawCode.substring(0, 5)}-${rawCode.substring(5)}';
                        if (context.mounted) Navigator.pop(context, validCode);
                        return;
                      }

                    } catch (e) {
                      debugPrint("Error OCR");
                    } finally {
                      _isProcessingOcr = false; 
                    }
                  }
                },
              ),

              Container(decoration: ShapeDecoration(shape: ScannerOverlayShape(borderColor: activeLaserColor))),

              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double laserY = (constraints.maxHeight - scanAreaHeight) / 2 + (scanAreaHeight * _animationController.value);
                  return Positioned(
                    top: laserY, left: (constraints.maxWidth - scanAreaWidth) / 2,
                    child: Container(
                      width: scanAreaWidth, height: 3.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.transparent, activeLaserColor, Colors.transparent], stops: const [0.0, 0.5, 1.0]),
                        boxShadow: [BoxShadow(color: activeLaserColor.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)],
                      ),
                    ),
                  );
                },
              ),

              Positioned(
                top: 40, left: 20,
                child: _buildFloatingButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
              ),

              Positioned(
                bottom: 95, right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: _isZoomed ? activeLaserColor.withOpacity(0.8) : Colors.black.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
                      child: IconButton(icon: Text(_isZoomed ? '2x' : '1x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), onPressed: _toggleZoom),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: _isOcrMode ? Colors.blueAccent.withOpacity(0.8) : Colors.black.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
                      child: IconButton(icon: const Icon(Icons.text_fields_rounded, color: Colors.white), onPressed: _toggleOcrMode),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _scannerController!,
                      builder: (context, state, child) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return _buildFloatingButton(icon: isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded, color: isTorchOn ? Colors.yellowAccent : Colors.white, onTap: () => _scannerController?.toggleTorch());
                      },
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 40, left: 0, right: 0,
                child: Column(
                  children: [
                    if (_isOcrMode)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blueAccent)),
                        child: Text(_lastOcrRead, style: const TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace', fontSize: 12)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isOcrMode ? Icons.document_scanner : Icons.center_focus_weak_rounded, color: activeLaserColor, size: 20),
                          const SizedBox(width: 10),
                          Text(_isOcrMode ? 'Aleje la etiqueta y enfoque' : 'Enfoque el código de barras', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
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

class ScannerOverlayShape extends ShapeBorder {
  final Color borderColor; 
  const ScannerOverlayShape({this.borderColor = Colors.white});
  @override EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);
  @override Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()..fillType = PathFillType.evenOdd..addPath(getOuterPath(rect), Offset.zero);
  @override Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    return Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd;
  }
  @override void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    canvas.drawPath(Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd, Paint()..color = Colors.black.withOpacity(0.8)..style = PaintingStyle.fill);
    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 4.0..strokeCap = StrokeCap.square;
    final double cl = 35.0;
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(0, -cl), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(0, -cl), borderPaint);
    final crosshairPaint = Paint()..color = borderColor.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    canvas.drawLine(rect.center - const Offset(10, 0), rect.center + const Offset(10, 0), crosshairPaint);
    canvas.drawLine(rect.center - const Offset(0, 10), rect.center + const Offset(0, 10), crosshairPaint);
  }
  @override ShapeBorder scale(double t) => this;
}

extension StringExtension on String {
  String take(int length) => this.length <= length ? this : substring(0, length);
}*/

























// ================ VERSIÓN 3.0 CON OCR MEJORADO Y REGEX MULTI-FORMATO =================
// Esta versión mantiene la funcionalidad de escaneo rápido, pero al activar el modo OCR, ahora puede detectar tanto los racks normales (AA-06-2) como las etiquetas densas (000LP - 00899692010) gracias a un nuevo regex más flexible. Además, se implementó un zoom automático al activar el OCR para facilitar la lectura de etiquetas pequeñas, y se mejoraron las instrucciones en pantalla para guiar al usuario. La vibración y el sonido de confirmación siguen presentes para una experiencia táctil y auditiva completa.


/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  bool _isScanned = false;
  bool _isZoomed = false; 

  // --- VARIABLES OCR ---
  bool _isOcrMode = false; 
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  String _lastOcrRead = "Enfoque y presione CAPTURAR";
  bool _isProcessingOcr = false; 
  
  // LA MEMORIA RAM DEL FRANCOTIRADOR: Aquí guardaremos el fotograma en vivo sin procesarlo
  Uint8List? _latestFrame; 

  // --- CONTROLADOR ---
  MobileScannerController? _scannerController;
  late AnimationController _animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initController(false);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _initController(bool isOcr) {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal, 
      detectionTimeoutMs: 300, 
      returnImage: isOcr, // Solo pedimos bytes en modo azul
      formats: const [
        BarcodeFormat.code128, 
        BarcodeFormat.code39,  
        BarcodeFormat.code93,  
        BarcodeFormat.ean13,   
        BarcodeFormat.itf,     
      ],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _scannerController?.dispose();
    _audioPlayer.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  void _toggleZoom() {
    setState(() {
      _isZoomed = !_isZoomed;
      double targetZoom = _isZoomed ? 0.75 : 0.0; 
      try {
        _scannerController?.setZoomScale(targetZoom);
      } catch (e) {
        debugPrint("Error de Zoom");
      }
      HapticFeedback.lightImpact(); 
    });
  }

  void _toggleOcrMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isOcrMode = !_isOcrMode;
      _lastOcrRead = "Enfoque y presione CAPTURAR";
      _latestFrame = null; // Limpiamos la memoria
      
      _scannerController?.dispose();
      _initController(_isOcrMode);

      Future.delayed(const Duration(milliseconds: 500), () {
         try {
           // MODO LUPA PARA ETIQUETA ENANA
           double autoZoom = _isOcrMode ? 0.75 : 0.0; 
           _scannerController?.setZoomScale(autoZoom);
           if (mounted) setState(() { _isZoomed = _isOcrMode; }); 
         } catch (e) {}
      });
    });
  }

  // --- EL GATILLO DEL FRANCOTIRADOR ---
  Future<void> _dispararOcr() async {
    if (_latestFrame == null || _isProcessingOcr) {
      HapticFeedback.vibrate(); // Aviso de error si no hay cámara aún
      return; 
    }
    
    setState(() {
      _isProcessingOcr = true;
      _lastOcrRead = "Analizando fotograma perfecto...";
    });
    
    HapticFeedback.mediumImpact();

    try {
      // 1. Guardamos el único fotograma bueno en milisegundos
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_ocr.jpg');
      await tempFile.writeAsBytes(_latestFrame!); 

      // 2. Extraemos el texto
      final inputImage = InputImage.fromFile(tempFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      String everything = recognizedText.text.toUpperCase();

      if (everything.isEmpty) {
        setState(() => _lastOcrRead = "No se vio texto. ¡Acérquese más!");
        return;
      }

      // 3. LA LICUADORA MATEMÁTICA (Buscamos la etiqueta rebelde)
      String denseText = everything.replaceAll(RegExp(r'[^A-Z0-9]'), '').replaceAll('O', '0');
      
      // ESTRATEGIA 1: Etiqueta Enana (000LP00899692010)
      final denseMatch = RegExp(r'[0-9A-Z]{5}\d{11}').firstMatch(denseText);
      if (denseMatch != null) {
        _isScanned = true;
        HapticFeedback.heavyImpact();
        await _audioPlayer.play(AssetSource('audio/beepscan.mp3'));
        String rawCode = denseMatch.group(0)!;
        String validCode = '${rawCode.substring(0, 5)}-${rawCode.substring(5)}';
        if (context.mounted) Navigator.pop(context, validCode);
        return;
      }

      // ESTRATEGIA 2: Rack (AA-06-2)
      final rackMatch = RegExp(r'[A-Z]{2}[-\s]*\d{2}[-\s]*\d').firstMatch(everything);
      if (rackMatch != null) {
        _isScanned = true;
        HapticFeedback.heavyImpact();
        await _audioPlayer.play(AssetSource('audio/beepscan.mp3'));
        String validCode = rackMatch.group(0)!.replaceAll(RegExp(r'\s+-\s+'), '-').replaceAll(' ', '');
        if (context.mounted) Navigator.pop(context, validCode);
        return;
      }

      // Si leímos basura o no enfocó bien:
      setState(() => _lastOcrRead = "No legible. Reintente. (${everything.take(15)})");

    } catch (e) {
      debugPrint("Error OCR: $e");
      setState(() => _lastOcrRead = "Error del motor. Reintente.");
    } finally {
      setState(() => _isProcessingOcr = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color activeLaserColor = _isOcrMode ? Colors.blueAccent : const Color(0xFF00E676);

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
              // 1. Cámara Base
              MobileScanner(
                key: ValueKey(_isOcrMode), 
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (BarcodeCapture capture) async {
                  if (_isScanned) return;

                  if (!_isOcrMode) {
                    // --- MODO CÓDIGO BARRAS (CONTINUO Y VELOZ) ---
                    for (final barcode in capture.barcodes) {
                      if (barcode.rawValue != null) {
                        _isScanned = true;
                        HapticFeedback.heavyImpact(); 
                        await _audioPlayer.play(AssetSource('audio/beepscan.mp3')); 
                        if (context.mounted) Navigator.pop(context, barcode.rawValue!);
                        break;
                      }
                    }
                  } else {
                    // --- MODO FRANCOTIRADOR (ALMACENAMOS EN RAM PERO NO DISPARAMOS) ---
                    if (capture.image != null) {
                       _latestFrame = capture.image; // Se actualiza 3 veces por segundo, sin lag
                    }
                  }
                },
              ),

              Container(decoration: ShapeDecoration(shape: ScannerOverlayShape(borderColor: activeLaserColor))),

              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double laserY = (constraints.maxHeight - scanAreaHeight) / 2 + (scanAreaHeight * _animationController.value);
                  return Positioned(
                    top: laserY, left: (constraints.maxWidth - scanAreaWidth) / 2,
                    child: Container(
                      width: scanAreaWidth, height: 3.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.transparent, activeLaserColor, Colors.transparent], stops: const [0.0, 0.5, 1.0]),
                        boxShadow: [BoxShadow(color: activeLaserColor.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)],
                      ),
                    ),
                  );
                },
              ),

              Positioned(
                top: 40, left: 20,
                child: _buildFloatingButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
              ),

              // Controles de Utilidad (Derecha)
              Positioned(
                bottom: 120, right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: _isZoomed ? activeLaserColor.withOpacity(0.8) : Colors.black.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
                      child: IconButton(icon: Text(_isZoomed ? '2x' : '1x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), onPressed: _toggleZoom),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: _isOcrMode ? Colors.blueAccent.withOpacity(0.8) : Colors.black.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
                      child: IconButton(icon: const Icon(Icons.text_fields_rounded, color: Colors.white), onPressed: _toggleOcrMode),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _scannerController!,
                      builder: (context, state, child) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return _buildFloatingButton(icon: isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded, color: isTorchOn ? Colors.yellowAccent : Colors.white, onTap: () => _scannerController?.toggleTorch());
                      },
                    ),
                  ],
                ),
              ),

              // EL GATILLO CENTRAL (Solo aparece en Modo Azul)
              if (_isOcrMode)
                Positioned(
                  bottom: 110,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _isProcessingOcr
                      ? const CircularProgressIndicator(color: Colors.blueAccent)
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 8,
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, size: 24),
                          label: const Text("CAPTURAR TEXTO", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          onPressed: _dispararOcr,
                        ),
                  ),
                ),

              // Mensajes Inferiores
              Positioned(
                bottom: 40, left: 0, right: 0,
                child: Column(
                  children: [
                    if (_isOcrMode)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8), border: Border.all(color: _isProcessingOcr ? Colors.amber : Colors.blueAccent)),
                        child: Text(_lastOcrRead, style: const TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isOcrMode ? Icons.document_scanner : Icons.center_focus_weak_rounded, color: activeLaserColor, size: 20),
                          const SizedBox(width: 10),
                          Text(_isOcrMode ? 'Encuadre la etiqueta y dispare' : 'Enfoque el código de barras', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
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

class ScannerOverlayShape extends ShapeBorder {
  final Color borderColor; 
  const ScannerOverlayShape({this.borderColor = Colors.white});
  @override EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);
  @override Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()..fillType = PathFillType.evenOdd..addPath(getOuterPath(rect), Offset.zero);
  @override Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    return Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd;
  }
  @override void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final scanArea = Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.35);
    canvas.drawPath(Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd, Paint()..color = Colors.black.withOpacity(0.8)..style = PaintingStyle.fill);
    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 4.0..strokeCap = StrokeCap.square;
    final double cl = 35.0;
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(0, cl), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(0, -cl), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(-cl, 0), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(0, -cl), borderPaint);
    final crosshairPaint = Paint()..color = borderColor.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    canvas.drawLine(rect.center - const Offset(10, 0), rect.center + const Offset(10, 0), crosshairPaint);
    canvas.drawLine(rect.center - const Offset(0, 10), rect.center + const Offset(0, 10), crosshairPaint);
  }
  @override ShapeBorder scale(double t) => this;
}

extension StringExtension on String {
  String take(int length) => this.length <= length ? this : substring(0, length);
}*/