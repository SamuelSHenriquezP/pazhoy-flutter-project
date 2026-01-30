# PazHoy 🌅

**PazHoy** es una aplicación móvil de frases inspiradoras y motivacionales diseñada para traer un momento de paz y reflexión a tu día. Cada día, descubre una nueva frase cuidadosamente seleccionada de grandes pensadores, escritores y líderes de la historia.

## ✨ Características

### 🎨 Personalización Avanzada

- **Editor de Estilos Visual**: Personaliza completamente la apariencia de tus frases favoritas
  - Selección de más de 10 tipografías elegantes (Google Fonts)
  - Paleta de colores para texto y fondo
  - Control de opacidad con slider invertido intuitivo (100% → 0%)
  - Imagen de fondo personalizada desde galería
  - Ajuste de espaciado, alineación y tamaño de fuente
  - Efectos de texto: sombras y contornos configurables

### 📱 Navegación y Exploración

- **Frase del Día**: Acceso rápido a la cita destacada diaria
- **Navegación Vertical**: Desliza verticalmente para explorar todas las frases
- **Búsqueda Inteligente**: Busca por texto o autor (con toggle para mostrar/ocultar)
- **Exploración por Categorías**: Navega frases agrupadas por autor o fuente
- **Aleatorio**: Descubre frases al azar con un solo toque

### 💾 Gestión de Contenido

- **Favoritos**: Marca tus frases preferidas para acceso rápido
- **Compartir**: Comparte frases como imagen personalizada
- **Guardar**: Guarda imágenes de frases directamente en tu galería
- **Persistencia**: Tu progreso, favoritos y estilos se guardan automáticamente

### 🎯 Interfaz de Usuario

- **Diseño Minimalista**: Fondo color hueso (#FFFEFA) que no distrae
- **FABs Organizados**: Botones flotantes para Guardar, Compartir y Editar
- **Barra Superior Limpia**: Búsqueda oculta por defecto, iconos intuitivos
- **Animaciones Suaves**: Transiciones fluidas entre estados

## 🛠️ Tecnologías

### Framework y Lenguaje

- **Flutter** 3.9.2+ - Framework de UI multiplataforma
- **Dart** - Lenguaje de programación

### Dependencias Principales

```yaml
dependencies:
  provider: ^6.1.5+1 # Gestión de estado
  shared_preferences: ^2.5.3 # Almacenamiento local
  google_fonts: ^6.1.0 # Tipografías
  screenshot: ^3.0.0 # Capturas de pantalla
  share_plus: ^12.0.1 # Compartir contenido
  gal: ^2.3.2 # Acceso a galería
  image_picker: ^1.0.7 # Selección de imágenes
  flutter_colorpicker: ^1.1.0 # Selector de color
  path_provider: ^2.1.1 # Rutas del sistema
```

## 📁 Estructura del Proyecto

```
pazhoy/
├── lib/
│   ├── main.dart                          # Punto de entrada
│   └── src/
│       ├── models/
│       │   └── quote.dart                 # Modelo de datos Quote
│       ├── providers/
│       │   ├── quotes_provider.dart       # Estado global de frases
│       │   └── style_provider.dart        # Estado de estilos
│       ├── services/
│       │   └── local_storage_service.dart # Persistencia local
│       ├── data/
│       │   └── quotes_repository.dart     # Carga de datos JSON
│       ├── pages/
│       │   ├── home_page.dart             # Pantalla principal
│       │   ├── details_page.dart          # Detalle de frase
│       │   └── explore_page.dart          # Exploración por categorías
│       └── widgets/
│           ├── quote_card.dart            # Tarjeta de frase
│           ├── modern_style_editor.dart   # Editor de estilos
│           └── style_editor_sheet.dart    # Hoja de estilos alternativa
├── assets/
│   ├── data/
│   │   └── quotes.json                    # Base de datos de frases
│   └── images/
│       └── app_icon.png                   # Icono de la app
├── android/                               # Configuración Android
├── test/
│   └── widget_test.dart                   # Tests unitarios
└── pubspec.yaml                           # Configuración del proyecto
```

## 🚀 Instalación y Ejecución

### Instalar la APK ubicada en "Releases"

### O ejecutar el proyecto desde Android Studio

- Flutter SDK 3.9.2 o superior
- Android Studio / VS Code con extensiones de Flutter
- Emulador Android o dispositivo físico

### Pasos

1. **Clonar el repositorio**

   ```bash
   cd PdeVerdad/P1/pazhoy
   ```

2. **Instalar dependencias**

   ```bash
   flutter pub get
   ```

3. **Ejecutar en modo desarrollo**

   ```bash
   flutter run
   ```

4. **Ejecutar tests**

   ```bash
   flutter test
   ```

5. **Generar APK de release**
   ```bash
   flutter build apk --release
   ```

## 📊 Datos

Las frases se almacenan en `assets/data/quotes.json` con la siguiente estructura:

```json
{
  "text": "Texto de la frase",
  "author": "Autor",
  "publish_date": "2026-01-30",
  "context": "Contexto opcional",
  "source": "Fuente de la frase"
}
```

- **Fecha de Publicación**: Las frases con `publish_date` futuro no se muestran hasta esa fecha
- **Frase del Día**: Se determina automáticamente por la fecha actual

## 🎨 Personalización de Estilos

Los estilos personalizados se guardan en `SharedPreferences` y persisten entre sesiones:

- **Fuente**: 10 opciones de Google Fonts
- **Colores**: Texto, fondo, sombra, contorno
- **Espaciado**: Padding, interlineado, espaciado de letras
- **Efectos**: Sombra (con blur), contorno (con grosor)
- **Fondo**: Color sólido o imagen personalizada
- **Opacidad**: Capa de color con transparencia ajustable

## 📱 Plataformas Soportadas

- ✅ **Android** (Probado en Android 5.0+)
- ⏳ **iOS** (Compatible pero no probado)

## 🔒 Permisos

### Android

- `WRITE_EXTERNAL_STORAGE` (API ≤ 29) - Para guardar imágenes en galería
- `INTERNET` - Para cargar fuentes de Google Fonts

## 🧪 Testing

El proyecto incluye tests automatizados:

- Test de widget principal
- Verificación de AppBar y título
- Validación de funcionalidad de búsqueda
- Comprobación de íconos de navegación

Ejecutar: `flutter test`

## 🎯 Roadmap Futuro

- [ ] Notificaciones diarias a las 9:00 AM
- [ ] Widget de Android para pantalla de inicio
- [ ] Temas predefinidos (Oscuro, Naturaleza, Minimalista, etc)
- [ ] Animaciones de transición entre frases

## 📄 Licencia

Este proyecto es de uso personal y portafolio.

## 👨‍💻 Desarrollo

Desarrollado con ❤️ usando Flutter

---

**PazHoy** - Un momento de paz cada día 🌸
