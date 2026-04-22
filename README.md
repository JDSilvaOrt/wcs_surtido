# WCS Surtido - Escáner Industrial Dual 🏭📱

Aplicación de grado industrial desarrollada en **Flutter** para la gestión ágil de inventarios y surtido en piso de almacén. Diseñada específicamente para operar en terminales de uso rudo (como Cubot KingKong y dispositivos Zebra), garantizando alta disponibilidad y velocidad de lectura en condiciones logísticas extremas.

## 🚀 Arquitectura de Lectura Dual

Para superar las limitaciones físicas del hardware en el autoenfoque de etiquetas de alta densidad, el sistema implementa una arquitectura de dos motores:

1. **Modo Láser (Velocidad Continua):** Utiliza `mobile_scanner` con el motor de video a baja resolución. Optimizado para lectura en ráfaga de códigos de barras estándar (Code 128, Code 39, EAN-13, ITF). Cero latencia y alto rendimiento.
2. **Modo Francotirador (OCR HD):** Desacopla el flujo de video y delega la captura a la cámara nativa de Android (`image_picker`) en su máxima resolución. Un motor embebido de **Google ML Kit Text Recognition** procesa el fotograma perfecto para extraer texto alfanumérico complejo y ubicaciones en milisegundos.

## ✨ Características Principales

* **Procesamiento Inteligente (Licuadora Matemática):** Filtros avanzados mediante Expresiones Regulares (Regex) que limpian ruido, toleran saltos de línea y corrigen automáticamente errores ópticos (ej. confusión del número `0` con la letra `O`).
* **Soporte Multi-Formato:** Detección automática de ubicaciones de Rack estándar (ej. `AA-06-2`) y etiquetas enanas de alta densidad (ej. `000LP-00899692010`).
* **Interfaz Ergonómica (Piso de Almacén):** Controles flotantes anclados a la zona inferior derecha, diseñados para operación a una sola mano (con o sin guantes), minimizando el tiempo de respuesta del operador.
* **Fallback Interactivo:** Si la etiqueta está gravemente dañada y el motor OCR extrae múltiples cadenas candidatas, se despliega un modal elegante (Bottom Sheet) para que el operador seleccione la cadena correcta con un solo toque.

## 🛠️ Stack Tecnológico

* **Framework:** Flutter / Dart
* **Lectura de Barras:** `mobile_scanner`
* **Visión Artificial (OCR):** `google_mlkit_text_recognition`
* **Captura HD:** `image_picker`
* **Audio Feedback:** `audioplayers` (Beeper industrial de confirmación)

## ⚙️ Instalación y Compilación

1. Clonar el repositorio:
   ```bash
   git clone [https://github.com/JDSilvaOrt/wcs_surtido.git](https://github.com/JDSilvaOrt/wcs_surtido.git)


## 🌎 Entorno de Desarrollo

Este proyecto fue desarrollado y probado con una configuración de entorno específica. Para evitar problemas de compatibilidad y asegurar que el proyecto compile correctamente, se recomienda encarecidamente utilizar las siguientes versiones de software.

### 🎯 Flutter & Dart

El proyecto utiliza una revisión (commit) de Git específica de Flutter para garantizar la consistencia.

* **Flutter:** `3.29.0`
* **Canal:** `stable`
* **Revisión (Commit):** `35c388afb5`
* **Dart:** `3.7.0`

**Cómo replicar este entorno:**

1.  **[Descarga e instala el SDK de Flutter](https://docs.flutter.dev/get-started/install)** (si aún no lo tienes).
2.  Navega hasta la carpeta donde instalaste Flutter (ej. `C:\dev\flutter`) en tu terminal.
3.  Ejecuta los siguientes comandos de Git para cambiar a la revisión exacta del proyecto:

    ```bash
    # Asegura que tienes la información más reciente del repositorio
    git fetch

    # Cambia tu SDK a la revisión exacta usada en este proyecto
    git checkout 35c388afb5
    ```

4.  Ejecuta `flutter doctor -v` para verificar que tu entorno coincida y descargar los artefactos de Dart correspondientes.

---

### 🤖 Desarrollo Android

* **Android Studio:** `2024.2`
    * **[Descargar Android Studio](https://developer.android.com/studio)**
* **Android SDK:** `35.0.1`
* **Build Tools:** `35.0.1`
* **Java:** `OpenJDK 21.0.4` (Viene incluido con Android Studio 2024.2)

**Pasos de configuración:**

1.  Instala Android Studio.
2.  Abre el **SDK Manager** (en Android Studio: `File` > `Settings` > `Languages & Frameworks` > `Android SDK`).
3.  En la pestaña **"SDK Platforms"**, asegúrate de que **"Android SDK Platform 35"** esté instalado.
4.  En la pestaña **"SDK Tools"**, asegúrate de que **"Android SDK Build-Tools 35.0.1"** esté instalado.
5.  **Importante:** Acepta las licencias de Android ejecutando el siguiente comando en tu terminal:

    ```bash
    flutter doctor --android-licenses
    ```

---

### 🪟 Desarrollo Windows (Opcional)

Si deseas compilar la versión de escritorio para Windows, necesitas:

* **Visual Studio 2022 Community**
    * **[Descargar Visual Studio](https://visualstudio.microsoft.com/es/vs/community/)**
* Durante la instalación, selecciona la carga de trabajo: **"Desarrollo de escritorio con C++"**.
* Asegúrate de que los siguientes **componentes individuales** están marcados:
    * `MSVC v142 - VS 2019 C++ x64/x86 build tools` (o la versión v143 más reciente)
    * `C++ CMake tools for Windows`
    * `Windows 10 SDK` (o Windows 11 SDK)

---

### 📝 Editores y Extensiones

* **VS Code:** `1.105.1`
    * **[Descargar VS Code](https://code.visualstudio.com/)**
* **Extensión de Flutter para VS Code:** `v3.120.0`
    * **[Instalar desde el Marketplace](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)**
