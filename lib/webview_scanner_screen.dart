import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Requerido para el MethodChannel
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scanner_screen.dart';

class WebviewScannerScreen extends StatefulWidget {
  const WebviewScannerScreen({super.key});

  @override
  State<WebviewScannerScreen> createState() => _WebviewScannerScreenState();
}

class _WebviewScannerScreenState extends State<WebviewScannerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _teclaSufijo = 'Enter';

  // --- 1. CONECTAMOS EL TÚNEL CON ANDROID NATIVO ---
  static const MethodChannel _hardwareChannel = MethodChannel('com.wms.scanner/hardware');

  @override
  void initState() {
    super.initState();
    _inicializarWebView();
    
    // --- 2. ESCUCHAMOS EL BOTÓN FÍSICO DESDE KOTLIN ---
    _hardwareChannel.setMethodCallHandler((call) async {
      if (call.method == 'volumePressed') {
        
        // Validamos que estemos en esta pantalla exacta 
        if (ModalRoute.of(context)?.isCurrent == true) {
          _abrirCamaraYEscribir();
        }
      }
    });
  }

  @override
  void dispose() {
    // --- 3. CERRAMOS LA ESCUCHA AL SALIR ---
    _hardwareChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _inicializarWebView() async {
    final prefs = await SharedPreferences.getInstance();
    final String url = prefs.getString('wms_url') ?? 'http://172.30.27.22:35500/Execute/Display';
    _teclaSufijo = prefs.getString('tecla_sufijo') ?? 'Enter';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _abrirCamaraYEscribir() async {
    final String? barcode = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen()));

    if (barcode != null && barcode.isNotEmpty) {
      String jsKeyEvent = '';
      if (_teclaSufijo == 'Enter') {
        jsKeyEvent = "activeField.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', keyCode: 13, bubbles: true }));";
      } else if (_teclaSufijo == 'Tabulador') {
        jsKeyEvent = "activeField.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab', keyCode: 9, bubbles: true }));";
      }

      final String jsCode = '''
        var activeField = document.activeElement;
        if (activeField && (activeField.tagName === 'INPUT' || activeField.tagName === 'TEXTAREA')) {
          activeField.value = '$barcode';
          activeField.dispatchEvent(new Event('input', { bubbles: true }));
          activeField.dispatchEvent(new Event('change', { bubbles: true }));
          $jsKeyEvent
        }
      ''';
      
      await _controller.runJavaScript(jsCode);
    }
  }

  Future<void> _confirmarRecarga() async {
    final bool confirmar = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.autorenew_rounded, color: Colors.blueAccent, size: 48),
                ),
                const SizedBox(height: 24),
                const Text('¿Recargar el Sistema?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text('La página volverá a cargar. Si estabas capturando un código y no lo has enviado, se perderá.', style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300, width: 2),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar', style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Recargar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      }
    ) ?? false;

    if (confirmar && context.mounted) {
      _controller.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recargando el portal...'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final bool confirmarSalida = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
              elevation: 8,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 48),
                    ),
                    const SizedBox(height: 24),
                    const Text('¿Salir del Sistema?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Text('Si tienes un proceso de almacén a medias, podrías perder tu progreso actual.\n¿Deseas volver al menú principal?', style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey.shade300, width: 2),
                            ),
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar', style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sí, salir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          }
        ) ?? false;

        if (confirmarSalida && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('WMS Dynamics AX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: Colors.black45,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.autorenew_rounded, size: 28),
                tooltip: 'Recargar sistema',
                onPressed: _confirmarRecarga,
              ),
            )
          ],
        ),
        body: WebViewWidget(controller: _controller),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _abrirCamaraYEscribir,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Escanear'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}