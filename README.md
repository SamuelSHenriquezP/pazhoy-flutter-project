# PazHoy 🕊️🧘 — Daily Mindfulness & Visual Quote Companion

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Notifications](https://img.shields.io/badge/Service-Local%20Notifications-success)]()
[![Author](https://img.shields.io/badge/Studio-Inventus%20Tech-orange)]()

> **PazHoy** es una aplicación de inspiración diaria, bienestar y reflexión personal (+6,400 líneas de código). Permite descubrir citas motivacionales, programar notificaciones a horas específicas del día, personalizar las tarjetas de frases con un editor visual tipográfico de vanguardia y crear colecciones privadas.

---

## 🌟 Características Principales

* **Editor de Estilos Tipográficos & Tarjetas Visuales (`ModernStyleEditor`):**
  * Personalización en tiempo real del tamaño de fuente, interlineado, paleta cromática, gradientes y estilo visual de las tarjetas para compartir en redes sociales.
* **Sistema de Notificaciones Diarias Programadas (`NotificationService`):**
  * Configuración de recordatorios matutinos y nocturnos mediante alarmas locales nativas de Android e iOS.
* **Gestión de Frases Propias & Colecciones Favoritas:**
  * Capacidad para que el usuario escriba sus propias reflexiones y las agrupe en carpetas temáticas.
* **Capa de Persistencia Redundante:**
  * Almacenamiento local mediante `LocalStorageService` con claves de respaldo automáticas (`user_custom_quotes_backup` y `user_collections_backup`) para proteger las reflexiones del usuario contra fallos de almacenamiento.
* **Monetización Equilibrada:**
  * Banners no intrusivos y anuncios premiados para desbloquear paquetes exclusivos de tipografías y fondos.

---

## 🏗️ Estructura del Código

```
pazhoy-flutter-project/
├── lib/
│   ├── src/
│   │   ├── models/
│   │   │   ├── quote_model.dart         # Estructura de frases, autores y categorías
│   │   │   └── collection_model.dart    # Carpetas de favoritos del usuario
│   │   ├── providers/
│   │   │   ├── style_provider.dart      # Estado de fuentes, colores y estilos visuales
│   │   │   └── premium_provider.dart    # Estado de suscripción y temas premium
│   │   ├── services/
│   │   │   ├── local_storage_service.dart # Persistencia con copias de seguridad automáticas
│   │   │   ├── notification_service.dart# Gestor de notificaciones locales nativas
│   │   │   └── ad_service.dart          # Módulo de publicidad
│   │   ├── widgets/
│   │   │   ├── quote_card.dart          # Tarjeta visual renderizable y exportable
│   │   │   └── modern_style_editor.dart # Selector de tipografías y colores
│   │   └── pages/
│   │       ├── home_page.dart           # Visualizador principal de citas
│   │       ├── settings_page.dart       # Horarios de notificación y respaldo
│   │       └── collections_page.dart    # Biblioteca de citas guardadas
│   └── main.dart                        # Inicialización y proveedores
```

---

## 🚀 Puesta en Marcha

```bash
cd PazHoy/pazhoy-flutter-project
flutter pub get
flutter run
```

---

**Desarrollado por Inventus Tech Studio** • *Liderado por Samuel Henríquez*
