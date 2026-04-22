import 'package:flutter/material.dart';
import 'scanner_screen.dart';

class InventoryFormScreen extends StatefulWidget {
  const InventoryFormScreen({super.key});

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final TextEditingController _almacenController = TextEditingController();
  final TextEditingController _localidadController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  Future<void> _escanearCodigo(TextEditingController controller) async {
    final String? resultado = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen()));
    if (resultado != null && resultado.isNotEmpty) setState(() => controller.text = resultado);
  }

  Widget _buildScanField({required String label, required TextEditingController controller, required IconData prefixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label, filled: true, fillColor: Colors.white,
          prefixIcon: Icon(prefixIcon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () => _escanearCodigo(controller)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Captura Manual')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScanField(label: 'Almacén', controller: _almacenController, prefixIcon: Icons.warehouse),
            _buildScanField(label: 'Localidad', controller: _localidadController, prefixIcon: Icons.location_on),
            _buildScanField(label: 'Modelo / SKU', controller: _modeloController, prefixIcon: Icons.inventory_2),
            _buildScanField(label: 'Cantidad', controller: _cantidadController, prefixIcon: Icons.numbers),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () { /* Enviar datos a la API configurada */ },
              child: const Text('PROCESAR ENTRADA'),
            ),
          ],
        ),
      ),
    );
  }
}