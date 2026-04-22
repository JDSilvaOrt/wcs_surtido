import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final TextEditingController _wmsUrlController = TextEditingController();
  
  // --- NUEVOS CONTROLADORES PARA EL SERVICIO SOAP ---
  final TextEditingController _soapUrlController = TextEditingController();
  final TextEditingController _ntlmUserController = TextEditingController();
  final TextEditingController _ntlmPassController = TextEditingController();
  final TextEditingController _ntlmDomainController = TextEditingController();

  final TextEditingController _adminUserController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();

  bool _isAuthenticated = false;
  bool _obscureAdminPassword = true;
  bool _obscureServicePassword = true;

  String _teclaSufijo = 'Enter'; 
  final List<String> _opcionesTecla = ['Enter', 'Tabulador', 'Ninguno'];

  final String _usuarioAdmin = 'adminwms';
  final String _passwordAdmin = 'R1v3rL4nd#2026';

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wmsUrlController.text = prefs.getString('wms_url') ?? 'http://172.30.27.22:35500/Execute/Display';
      _teclaSufijo = prefs.getString('tecla_sufijo') ?? 'Enter';
      
      // Cargamos credenciales del servicio SOAP
      _soapUrlController.text = prefs.getString('soap_url') ?? 'http://172.30.27.22/RivStockItemSkuService/RivStockItemSkuServiceIIS/xppservice.svc';
      _ntlmUserController.text = prefs.getString('ntlm_user') ?? '';
      _ntlmPassController.text = prefs.getString('ntlm_pass') ?? '';
      _ntlmDomainController.text = prefs.getString('ntlm_domain') ?? '';
    });
  }

  Future<void> _guardarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wms_url', _wmsUrlController.text);
    await prefs.setString('tecla_sufijo', _teclaSufijo);
    
    // Guardamos credenciales del servicio SOAP
    await prefs.setString('soap_url', _soapUrlController.text);
    await prefs.setString('ntlm_user', _ntlmUserController.text);
    await prefs.setString('ntlm_pass', _ntlmPassController.text);
    await prefs.setString('ntlm_domain', _ntlmDomainController.text);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada correctamente', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        )
      );
      Navigator.pop(context);
    }
  }

  void _intentarLogin() {
    if (_adminUserController.text == _usuarioAdmin && _adminPasswordController.text == _passwordAdmin) {
      setState(() => _isAuthenticated = true);
      FocusScope.of(context).unfocus(); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales incorrectas'), backgroundColor: Colors.redAccent)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Configuración del Sistema', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600), 
            child: _isAuthenticated ? _buildConfigView() : _buildLoginView(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.admin_panel_settings, size: 64, color: Colors.blueGrey),
        const SizedBox(height: 16),
        const Text('Autenticación Requerida', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        TextField(
          controller: _adminUserController,
          decoration: const InputDecoration(labelText: 'Usuario Admin', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _adminPasswordController,
          obscureText: _obscureAdminPassword,
          decoration: InputDecoration(
            labelText: 'Contraseña Admin', 
            border: const OutlineInputBorder(), 
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(icon: Icon(_obscureAdminPassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscureAdminPassword = !_obscureAdminPassword)),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(onPressed: _intentarLogin, child: const Text('INGRESAR'))
      ],
    );
  }

  Widget _buildConfigView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Parámetros Webview WMS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        const Divider(),
        TextField(
          controller: _wmsUrlController,
          decoration: const InputDecoration(labelText: 'URL Dynamics AX', border: OutlineInputBorder(), prefixIcon: Icon(Icons.web)),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _teclaSufijo,
          decoration: const InputDecoration(labelText: 'Acción después de escanear web', border: OutlineInputBorder(), prefixIcon: Icon(Icons.keyboard_return)),
          items: _opcionesTecla.map((String op) => DropdownMenuItem(value: op, child: Text(op))).toList(),
          onChanged: (String? val) => setState(() { if (val != null) _teclaSufijo = val; }),
        ),
        
        const SizedBox(height: 40),
        
        const Text('Credenciales de Servicio SOAP (Inventario)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
        const Divider(),
        TextField(
          controller: _soapUrlController,
          decoration: const InputDecoration(labelText: 'URL Servicio SOAP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.api)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ntlmDomainController,
                decoration: const InputDecoration(labelText: 'Dominio', border: OutlineInputBorder(), prefixIcon: Icon(Icons.domain)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _ntlmUserController,
                decoration: const InputDecoration(labelText: 'Usuario NTLM', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_pin)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ntlmPassController,
          obscureText: _obscureServicePassword,
          decoration: InputDecoration(
            labelText: 'Contraseña NTLM', 
            border: const OutlineInputBorder(), 
            prefixIcon: const Icon(Icons.password),
            suffixIcon: IconButton(icon: Icon(_obscureServicePassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscureServicePassword = !_obscureServicePassword)),
          ),
        ),

        const SizedBox(height: 40),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white),
          onPressed: _guardarConfiguracion,
          icon: const Icon(Icons.save),
          label: const Text('GUARDAR CAMBIOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        )
      ],
    );
  }
}