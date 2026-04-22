package com.example.wcs_surtido

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.wms.scanner/hardware"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Creamos un "túnel" de comunicación hacia Flutter
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // Interceptamos el botón físico de subir o bajar volumen
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            
            // Le disparamos una señal invisible a Flutter
            methodChannel?.invokeMethod("volumePressed", null)
            
            // Retornamos 'true' para bloquear Android. 
            // ¡Esto evita que salga la molesta barra de volumen en la pantalla!
            return true 
        }
        // Si presiona otro botón (como el de apagado), dejamos que Android actúe normal
        return super.onKeyDown(keyCode, event)
    }
}
