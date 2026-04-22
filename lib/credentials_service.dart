import 'package:ntlm/ntlm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

class CredentialsService {
  static Future<NTLMClient> getNtlmClient() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Leemos la memoria y usamos .trim() para asesinar espacios en blanco invisibles
    final String domain = (prefs.getString('ntlm_domain') ?? '').trim();
    final String username = (prefs.getString('ntlm_user') ?? '').trim();
    final String password = (prefs.getString('ntlm_pass') ?? '').trim();

    // Diagnóstico en consola para confirmar qué estamos leyendo realmente
    log("=== LECTURA DE CONFIGURACIÓN NTLM ===");
    log("Dominio a enviar: [$domain]");
    log("Usuario a enviar: [$username]");
    log("Longitud de contraseña: ${password.length} caracteres");
    log("=====================================");

    if (domain.isEmpty || username.isEmpty || password.isEmpty) {
      throw Exception('Credenciales NTLM incompletas. Por favor, llénelas en la pantalla de Configuración.');
    }

    return NTLMClient(
      domain: domain,
      username: username,
      password: password,
    );
  }
}