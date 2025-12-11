# 🐾 Zoonet Front-End (Rastreador GPS y Comunidad para Mascotas) 🐾

**Zoonet Front-End** es la aplicación móvil desarrollada con **Flutter** para la plataforma **Zoonet**.
Permite a los usuarios monitorear la ubicación de su mascota mediante GPS, definir zonas de seguridad, interactuar en un feed social y utilizar herramientas avanzadas para encontrar mascotas perdidas.

El proyecto está diseñado bajo un modelo **Freemium**, diferenciando las funcionalidades clave para usuarios **FREE** y **Premium**.

---

## 🚀 Características Destacadas

La aplicación se estructura en torno a las siguientes funcionalidades principales:

| Módulo             | Característica                  | Plan FREE                                             | Plan PREMIUM                                                                |
| ------------------ | ------------------------------- | ----------------------------------------------------- | --------------------------------------------------------------------------- |
| **Rastreo**        | Ubicación en Vivo               | Rastreo con actualizaciones cada 10 segundos.         | Rastreo en Tiempo Real (misma frecuencia, considerado Premium por backend). |
| **Seguridad**      | Zonas Seguras (Geofencing)      | 1 Zona límite.                                        | Ilimitadas.                                                                 |
| **Emergencia**     | Reporte de Mascota Perdida      | Límite de reportes activos.                           | Ilimitado (alerta a toda la comunidad).                                     |
| **Avanzado**       | AI Matching (Búsqueda por Foto) | No Disponible.                                        | Disponible (usa IA para buscar coincidencias).                              |
| **Historial**      | Historial de Rutas              | No Disponible.                                        | Disponible (filtros por Semana, Mes, Año).                                  |
| **Notificaciones** | Push y Locales                  | Soportado mediante FCM y flutter_local_notifications. | Soportado.                                                                  |

---

## 🛠️ Tecnologías del Front-End

Este proyecto Flutter utiliza las siguientes dependencias clave:

* **flutter**: SDK de desarrollo de Google.
* **google_maps_flutter**: Mapas de Google para visualización y rastreo.
* **geocoding / location**: Servicios de geocodificación y GPS.
* **firebase_core / firebase_messaging**: Integración con Firebase para notificaciones.
* **flutter_local_notifications**: Manejo de notificaciones locales.
* **http / image_picker / mime**: API REST + subida de imágenes.
* **timeago**: Fechas relativas (ej. “hace 5 minutos”).

---

## ⚙️ Configuración y Puesta en Marcha

### 1. Requisitos Previos

* Flutter SDK (versión estable).
* Back-End Zoonet (Java / Spring Boot o equivalente) en ejecución.

---

### 2. Clonación y Dependencias

Asumiendo que te encuentras en el directorio raíz del proyecto Flutter (`zoonet_front`):

```bash
# Obtener dependencias
flutter pub get
```

---

### 3. Configuración de API y Servicios

#### A. Configuración de URL del Back-End

Las URLs base de conexión al back-end se definen en:

```
lib/services/auth_service.dart
```

Valores por defecto:

* **Android Emulator:** `http://10.0.2.2:8080`
* **iOS / Web / Desktop:** `http://localhost:8080`

Si su backend corre en otra dirección, modifique:

```dart
_androidEmulatorUrl
_iosSimulatorUrl
```

---

#### B. Clave de API de Google Maps

Reemplazar la clave por una propia:

##### **Android**

Archivo:

```
android/app/src/main/AndroidManifest.xml
```

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyDnDtlZ-aLv63nfk1VV01Fa9ui7BAxRAXM" />
```

##### **Web**

Archivo:

```
web/index.html
```

```html
<script src="https://maps.googleapis.com/maps/api/js?key=API_KEY&libraries=places"></script>
```

---

## ▶️ Ejecución

Para ejecutar la app en un dispositivo o emulador conectado:

```bash
flutter run
```

