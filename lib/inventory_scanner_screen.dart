import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'inventory_screen.dart'; // Importamos el modelo con las 2 memorias
import 'stock_item_service.dart';

class InventoryScannerScreen extends StatefulWidget {
  final List<InventoryItem> scannedItems;

  const InventoryScannerScreen({super.key, required this.scannedItems});

  @override
  State<InventoryScannerScreen> createState() => _InventoryScannerScreenState();
}

class _InventoryScannerScreenState extends State<InventoryScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 500, 
    returnImage: false,
  );
  
  late AnimationController _animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isProcessing = false;
  
  String _lastScannedCode = '';
  DateTime _lastScanTime = DateTime.now();

  static const MethodChannel _hardwareChannel = MethodChannel('com.wms.scanner/hardware');

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), 
    )..repeat(reverse: true);

    _hardwareChannel.setMethodCallHandler((call) async {
      if (call.method == 'volumePressed') return; 
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _scannerController.dispose();
    _audioPlayer.dispose();
    //_hardwareChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _handleScan(String code) async {
    if (code.length != 13) return; 
    if (_isProcessing) return; 

    final now = DateTime.now();
    if (code == _lastScannedCode && now.difference(_lastScanTime).inMilliseconds < 1500) {
      return; 
    }
    
    _lastScannedCode = code;
    _lastScanTime = now;
    
    setState(() => _isProcessing = true);

    try {
      int existingIndex = widget.scannedItems.indexWhere((item) => item.barcode == code);
      
      if (existingIndex != -1) {
        // Alimenta ambas memorias simultáneamente
        widget.scannedItems[existingIndex].maxScannedCount++; 
        widget.scannedItems[existingIndex].quantity++;        
        // --------------------------
        
        await _triggerSuccessFeedback();
        _showQuickToast('¡Suma exitosa! (+1)', Colors.green.shade700);
      } else {
        final response = await StockItemService.fetchInventoryId(code);

        if (response != null && response.success) {
          final sku = response.inventoryId.isNotEmpty ? response.inventoryId : 'SKU-$code';
          // Al insertarlo, ambas memorias (quantity y maxScannedCount) inician en 1
          widget.scannedItems.insert(0, InventoryItem(barcode: code, skuDescription: sku));
          
          await _triggerSuccessFeedback();
          _showQuickToast('Nuevo: $sku', Colors.blue.shade700);
        } else {
          _triggerErrorFeedback('SKU no encontrado');
        }
      }
    } catch (e) {
      _triggerErrorFeedback('Error de conexión');
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _triggerSuccessFeedback() async {
    try {
      HapticFeedback.heavyImpact();
      if (_audioPlayer.state != PlayerState.playing) {
        await _audioPlayer.play(AssetSource('audio/beep.mp3')); 
      }
    } catch (e) {
      debugPrint("Sin audio");
    }
  }

  void _triggerErrorFeedback(String message) {
    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 150), () => HapticFeedback.vibrate());
    _showQuickToast(message, Colors.redAccent);
  }

  void _showQuickToast(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars(); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(milliseconds: 800), 
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
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
              MobileScanner(
                controller: _scannerController,
                scanWindow: scanWindow,
                onDetect: (capture) {
                  if (_isProcessing) return;
                  for (final barcode in capture.barcodes) {
                    if (barcode.rawValue != null) {
                      _handleScan(barcode.rawValue!);
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
                    top: laserY,
                    left: (constraints.maxWidth - scanAreaWidth) / 2,
                    child: Container(
                      width: scanAreaWidth,
                      height: 3.0,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.transparent, Color(0xFF00E676), Colors.transparent], stops: [0.0, 0.5, 1.0]),
                        boxShadow: [BoxShadow(color: const Color(0xFF00E676).withOpacity(0.6), blurRadius: 10, spreadRadius: 2)],
                      ),
                    ),
                  );
                },
              ),

              Positioned(
                top: 40, 
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFloatingButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
                    ValueListenableBuilder(
                      valueListenable: _scannerController,
                      builder: (context, state, child) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return _buildFloatingButton(
                          icon: isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                          color: isTorchOn ? Colors.yellowAccent : Colors.white,
                          onTap: () => _scannerController.toggleTorch(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              if (_isProcessing)
                const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),

              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.center_focus_weak_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Enfoque el código de barras', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5), 
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1), 
      ),
      child: IconButton(icon: Icon(icon, color: color, size: 28), onPressed: onTap),
    );
  }
}

class ScannerOverlayShape extends ShapeBorder {
  const ScannerOverlayShape();

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
    final backgroundPath = Path()..addRect(rect)..addRect(scanArea)..fillType = PathFillType.evenOdd;
    canvas.drawPath(backgroundPath, backgroundPaint);

    final borderPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 4.0..strokeCap = StrokeCap.square; 
    final double cornerLength = 35.0; 

    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(cornerLength, 0), borderPaint);
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(0, cornerLength), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(-cornerLength, 0), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(0, cornerLength), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(cornerLength, 0), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(0, -cornerLength), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(-cornerLength, 0), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(0, -cornerLength), borderPaint);

    final crosshairPaint = Paint()..color = Colors.white.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final Offset center = rect.center;
    final double crosshairSize = 10.0; 

    canvas.drawLine(center - Offset(crosshairSize, 0), center + Offset(crosshairSize, 0), crosshairPaint);
    canvas.drawLine(center - Offset(0, crosshairSize), center + Offset(0, crosshairSize), crosshairPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}