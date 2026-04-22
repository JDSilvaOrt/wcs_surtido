import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'webview_scanner_screen.dart';
import 'config_screen.dart';
import 'splash_screen.dart'; // SplashScreen para mostrarlo al iniciar la app
//import 'inventory_screen.dart';
// import 'stock_item_service.dart';

void main() {
  // Siempre es buena práctica dejar esta línea cuando usamos plugins o cerramos la app
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Operativo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100], // Un fondo un poco más claro y limpio
      ),
      home: const SplashScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  // Función - diálogo para cerrar la app
  Future<bool> _mostrarDialogoSalida(BuildContext context) async {
    return await showDialog(
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
                // Ícono de salida
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¿Deseas cerrar la Aplicación?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Estás a punto de salir de la aplicación.',
                  style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
                  textAlign: TextAlign.justify,
                ),
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
                        child: const Text('Salir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos si es tablet o celular para mandar la variable a las tarjetas
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    // Envolvemos el Scaffold en PopScope para atrapar el botón físico de "Atrás"
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final bool confirmarSalida = await _mostrarDialogoSalida(context);

        if (confirmarSalida) {
          // Cierra la aplicación de forma nativa en Android
          SystemNavigator.pop(); 
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Menú Principal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.5)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: Colors.black45,
          // Mismo borde redondeado que en el WMS
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.settings_rounded, size: 28),
                tooltip: 'Configuración',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConfigScreen()),
                ),
              ),
            )
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- SECCIÓN DE BIENVENIDA ---
                  const SizedBox(height: 10),
                  Text(
                    textAlign: TextAlign.center,
                    'Bienvenido al Sistema',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    textAlign: TextAlign.justify,
                    'Seleccione un módulo operativo para trabajar.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  // ------------------------------------------------

                  Expanded(
                    child: GridView.count(
                      crossAxisCount: isTablet ? 2 : 1,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: isTablet ? 1.3 : 1.5, // Ajuste responsivo para el Grid
                      children: [
                        _MenuCard(
                          title: 'WMS',
                          textAlign: TextAlign.justify,
                          subtitle: 'Acceso al portal de control de inventarios de Dynamics AX 2012 R3',
                          icon: Icons.language_rounded,
                          color: Colors.teal,
                          imagePath: 'assets/images/AX.png',
                          isTablet: isTablet, // <-- Pasamos el dato
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WebviewScannerScreen())),
                        ),
                        /*_MenuCard(
                          title: 'Inventario Rápido',
                          subtitle: 'Conteo y suma de SKUs',
                          icon: Icons.inventory_2_outlined,
                          color: const Color(0xFF0F172A),
                          isTablet: isTablet, // <-- Pasamos el dato
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen())),
                        ),*/
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? imagePath;
  final TextAlign? textAlign;
  final bool isTablet; // <-- ¡AQUÍ ESTÁ LA VARIABLE FALTANTE!

  const _MenuCard({
    required this.title, 
    required this.subtitle, 
    required this.icon, 
    required this.color, 
    required this.onTap,
    required this.isTablet, // <-- LA HACEMOS OBLIGATORIA
    this.imagePath,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    // Calculamos tamaños dinámicos basándonos en si es tablet o celular
    final double iconSize = isTablet ? 64.0 : 48.0;
    final double titleSize = isTablet ? 24.0 : 20.0;
    final double subtitleSize = isTablet ? 15.0 : 13.0;

    return Card(
      elevation: 3, // Sombra sutil
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Bordes más suaves
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.1), // Efecto de onda del mismo color que el tema de la tarjeta
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 24.0 : 16.0), // Padding dinámico
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imagePath != null && imagePath!.isNotEmpty)
                Image.asset(
                  imagePath!,
                  height: iconSize, // Tamaño dinámico 
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(icon, size: iconSize, color: color);
                  },
                )
              else
                Icon(icon, size: iconSize, color: color),
                
              SizedBox(height: isTablet ? 20 : 12),
              
              Text(
                title, 
                style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                subtitle, 
                textAlign: textAlign ?? TextAlign.center, 
                style: TextStyle(color: Colors.grey[600], fontSize: subtitleSize),
                maxLines: 3,
                overflow: TextOverflow.ellipsis, // Si es muy largo, pone "..." en vez de desbordarse
              ),
            ],
          ),
        ),
      ),
    );
  }
}