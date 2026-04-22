import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io'; 
import 'inventory_scanner_screen.dart'; 

// --- MODELO DE DATOS ---
class InventoryItem {
  final String barcode;
  final String skuDescription;
  int quantity;            // Cantidad actual visible y exportable
  int maxScannedCount;     // El tope máximo físico que ha leído el láser

  InventoryItem({
    required this.barcode, 
    required this.skuDescription, 
    this.quantity = 1,
    this.maxScannedCount = 1, 
  });
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<InventoryItem> _scannedItems = [];
  
  // --- CONEXIÓN CON HARDWARE (KOTLIN) ---
  static const MethodChannel _hardwareChannel = MethodChannel('com.wms.scanner/hardware');

  @override
  void initState() {
    super.initState();
    _conectarBotonesVolumen();
  }

  void _conectarBotonesVolumen() {
    _hardwareChannel.setMethodCallHandler((call) async {
      if (call.method == 'volumePressed') {
        // Solo abrir si esta pantalla está activa
        if (ModalRoute.of(context)?.isCurrent == true) {
          _abrirEscaner();
        }
      }
    });
  }

  @override
  void dispose() {
    // Importante: Limpiar el handler al destruir la pantalla
    _hardwareChannel.setMethodCallHandler(null);
    super.dispose();
  }

  // --- LÓGICA DE NAVEGACIÓN ---
  Future<void> _abrirEscaner() async {
    HapticFeedback.mediumImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryScannerScreen(scannedItems: _scannedItems),
      ),
    );
    
    // FIX PREMIUM: Pequeño retraso para evitar conflictos de tiempo con el dispose del escáner
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Reconectar handler de volumen al volver
    _conectarBotonesVolumen(); 
    if (mounted) setState(() {});
  }

  // Diálogo para confirmar la salida si hay datos
  Future<void> _solicitarConfirmacionSalida(BuildContext context) async {
    final bool? darPermisoParaSalir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 12),
            Text('¿Salir y borrar datos?', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5)),
          ],
        ),
        content: const Text(
          'Tienes artículos escaneados sin exportar. Si sales ahora, perderás todo el progreso del conteo actual.',
          style: TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
        actions: [
          TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            onPressed: () => Navigator.pop(context, false), // No salir
            child: const Text('Quedarme', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444), // Rojo Alerta
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(context, true), // Sí salir
            child: const Text('Salir y Borrar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (darPermisoParaSalir == true && context.mounted) {
      // Usamos el root navigator para salir completamente de esta pantalla
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // --- LÓGICA DE GESTIÓN DE ITEMS ---
  void _clearAll() {
    setState(() => _scannedItems.clear());
  }

  void _deleteItem(int index) {
    HapticFeedback.lightImpact();
    setState(() => _scannedItems.removeAt(index));
  }

  void _incrementQuantity(int index) {
    final item = _scannedItems[index];
    // Regla: No subir más allá de lo que el láser leyó físicamente
    if (item.quantity < item.maxScannedCount) {
      HapticFeedback.selectionClick(); 
      setState(() => item.quantity++);
    } else {
      HapticFeedback.vibrate(); // Feedback de error sutil
    }
  }

  Future<void> _decrementQuantity(int index) async {
    final item = _scannedItems[index];
    HapticFeedback.selectionClick();

    if (item.quantity > 1) {
      setState(() => item.quantity--);
    } else {
      // Confirmar eliminación si llega a 1
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('¿Eliminar artículo?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Se eliminará el registro del código ${item.barcode}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, elevation: 0),
              onPressed: () => Navigator.pop(context, true), 
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirm == true) _deleteItem(index);
    }
  }

  // --- LÓGICA DE EXPORTACIÓN ---
  Future<void> _exportToCSV() async {
    final TextEditingController nameController = TextEditingController();

    final String? fileName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Exportar Inventario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Nombre del archivo', 
            hintText: 'Ej. Pasillo_A', 
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.description_outlined)
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (fileName != null && fileName.isNotEmpty) {
      try {
        final now = DateTime.now();
        final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
        final String fullFileName = '${fileName}_$timestamp.csv';
        
        final Directory downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) throw Exception("No se encontró carpeta Descargas");

        final File file = File('${downloadDir.path}/$fullFileName');
        StringBuffer csvContent = StringBuffer();
        csvContent.writeln("SKU,Modelo,Cantidad"); 
        for (var item in _scannedItems) {
          csvContent.writeln('"${item.barcode}","${item.skuDescription}",${item.quantity}');
        }

        await file.writeAsString(csvContent.toString());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text('Guardado en Descargas: $fullFileName'))]), 
            backgroundColor: const Color(0xFF10B981), 
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Error al guardar archivo.'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating));
      }
    }
  }

  // --- DISEÑO DE LA INTERFAZ (UI) ---
  @override
  Widget build(BuildContext context) {
    // PopScope intercepta el botón de atrás (físico o de la AppBar)
    return PopScope(
      // Si está vacío, permite salir directo. Si tiene datos, bloquea y ejecuta onPopInvoked
      canPop: _scannedItems.isEmpty,
      onPopInvoked: (didPop) async {
        // Si canPop fue true, didPop es true, ya salimos. No hacemos nada.
        if (didPop) return;
        
        // Si canPop fue false, didPop es false. Mostramos el diálogo de confirmación.
        await _solicitarConfirmacionSalida(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Fondo Slate
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Inventario', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5, fontSize: 22)),
          backgroundColor: const Color(0xFF0F172A), // Slate Oscuro Premium
          foregroundColor: Colors.white,
          elevation: 0,
          
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () async {
              // Si está vacío sale directo, sino pregunta
              if (_scannedItems.isEmpty) {
                Navigator.of(context).pop();
              } else {
                await _solicitarConfirmacionSalida(context);
              }
            },
          ),
          actions: [
            if (_scannedItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: 'Borrar todo',
                  onPressed: () async {
                    HapticFeedback.heavyImpact();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('¿Vaciar conteo?', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text('Se eliminarán todos los códigos escaneados. Esta acción no se puede deshacer.', style: TextStyle(height: 1.5)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600))),
                          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, elevation: 0), onPressed: () => Navigator.pop(context, true), child: const Text('Vaciar Todo', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    );
                    if (confirm == true) _clearAll();
                  },
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Sub-header decorativo oscuro sutil
            Container(
              width: double.infinity,
              height: 16,
              decoration: const BoxDecoration(color: Color(0xFF0F172A), borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
            ),
            
            Expanded(
              child: _scannedItems.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _scannedItems.length,
                      itemBuilder: (context, index) {
                        final item = _scannedItems[index];
                        final bool canIncrement = item.quantity < item.maxScannedCount;

                        return Dismissible(
                          key: Key('${item.barcode}_$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                          ),
                          onDismissed: (direction) => _deleteItem(index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Ícono Indigo Premium
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFFE0E7FF), Color(0xFFEEF2FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                      borderRadius: BorderRadius.circular(16)
                                    ),
                                    child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF4F46E5), size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Textos centrales
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.skuDescription, 
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1E293B), letterSpacing: -0.3), 
                                          maxLines: 2, 
                                          overflow: TextOverflow.ellipsis
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                          child: Text(item.barcode, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 12),

                                  // --- CONTROL STEPPER (Píldora) ---
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(100), // Forma de píldora
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // BOTÓN MENOS 
                                        InkWell(
                                          onTap: () => _decrementQuantity(index),
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(100)),
                                          child: const Padding(
                                            padding: EdgeInsets.all(10), 
                                            // Cambiado color a Rojo
                                            child: Icon(Icons.remove_rounded, color: Color(0xFFEF4444), size: 20)
                                          ),
                                        ),
                                        
                                        SizedBox(
                                          width: 30,
                                          child: Text(
                                            '${item.quantity}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                                          ),
                                        ),
                                        
                                        // BOTÓN MÁS (VERDE SI SE PUEDE, GRIS SI NO)
                                        InkWell(
                                          onTap: canIncrement ? () => _incrementQuantity(index) : null,
                                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(100)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(10), 
                                            child: Icon(Icons.add_rounded, color: canIncrement ? const Color(0xFF10B981) : Colors.grey.shade300, size: 20)
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            // --- BARRA INFERIOR DE ACCIONES ---
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.05), blurRadius: 24, offset: const Offset(0, -8))],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_scannedItems.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Artículos', style: TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              '${_scannedItems.fold(0, (sum, item) => sum + item.quantity)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A), // Slate 900
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: _abrirEscaner,
                            icon: const Icon(Icons.document_scanner_rounded, size: 24),
                            label: const Text('Escanear', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.2)),
                          ),
                        ),
                        
                        if (_scannedItems.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: _exportToCSV,
                              icon: const Icon(Icons.ios_share_rounded, size: 20),
                              label: const Text('Exportar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET PARA PANTALLA VACÍA ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Slate 100
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, size: 70, color: Color(0xFF94A3B8)), // Slate 400
          ),
          const SizedBox(height: 32),
          const Text('Inventario Vacío', style: TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Presione Escanear o use los botones físicos de volumen para iniciar el conteo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}