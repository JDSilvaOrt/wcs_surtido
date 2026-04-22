import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Configuramos una animación suave de aparición
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // 2. Temporizador para ir al Menú Principal
    _navigateToMain();
  }

  Future<void> _navigateToMain() async {
    // 3 segundos de exhibición del logo y los créditos
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainMenuScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Transición de fundido hacia el menú principal
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // ---  COLORES PERSONALIZADOS ---
    const Color splashBackgroundColor = Color.fromARGB(255, 18, 22, 23); // Gris/Negro oscuro
    const Color logoColor = Color.fromARGB(255, 200, 20, 15); // Rojo corporativo
    const Color textColor = Colors.white70;

    return Scaffold(
      backgroundColor: splashBackgroundColor,
      body: Center(
        // Envolvemos todo en el FadeTransition
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              
              // === LOGO DE LA APLICACIÓN ===
              Image.asset(
                'assets/images/logo-splash.png', 
                width: size.width * 0.45, 
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),

              // === INDICADOR DE CARGA ===
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(logoColor),
                strokeWidth: 3.5, 
              ),
              const SizedBox(height: 32),

              // === TEXTOS DE SISTEMA ===
              Text(
                'Cargando Sistema WMS...',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              
              // === CRÉDITOS Y COPYRIGHT ===
              Text(
                'Riverline Ergonomic © 2026',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.8),
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Desarrollado por: Ing. David Silva',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: logoColor, 
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}