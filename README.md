# TuAliado

> **"Te acompaña en la gestión de tu salud"**

**TuAliado** es una solución humanitaria desarrollada con **Flutter** para acompañar a las personas en la gestión de su salud, haciendo que el proceso sea más fácil, claro y tranquilo.

Gestionar la salud suele implicar documentos, órdenes, autorizaciones, medicamentos, resultados de laboratorio, citas y tareas administrativas. **TuAliado** busca reducir esa carga organizativa y brindar claridad sin reemplazar a las instituciones ni a los profesionales de la salud.

---

## Propósito e identidad

- **Acompañamiento permanente:** Combina claridad, empatía, organización y confianza para que el usuario entienda qué pasos seguir y mantenga el control de su información.
- **Tecnología al servicio de la persona:** Más que acumular funciones, prioriza aliviar la carga cotidiana y dar tranquilidad.

---

## Funcionalidades clave

- **Interpretación y clarificación de laboratorio con IA:** Analiza resultados actuales de laboratorio para ayudar a comprenderlos con mayor claridad (siempre como apoyo informativo y sin sustituir criterio médico profesional).
- **Nutrición personalizada con IA:** Recomienda un menú diario alineado con el análisis de laboratorio y el contexto del usuario.
- **Seguimiento de evolución en las 4 Reglas de Oro:**
  1. **Movimiento**
  2. **Sueño y Luz**
  3. **Estrés y Descanso**
  4. **Nutrición**
- **Gestión y organización:** Apoyo para mantener ordenados procesos, registros y seguimiento cotidiano.

---

## Stack tecnológico

- **Frontend / Multiplataforma:** Flutter & Dart
- **Inteligencia Artificial:** Modelos de IA / Gemini Vision para análisis y asistencia
- **Backend / Persistencia:** Supabase y almacenamiento local

---

## Ejecución local

1. Clona el repositorio:
   ```bash
   git clone https://github.com/Jaav07/TuAliado.git
   cd TuAliado

   ```

   ## Configuración de API Key (Google AI Studio) / API Key Setup 

**TuAliado** se publica sin claves de API incluidas en el código por seguridad. Para utilizar las funciones asistidas por IA (como la interpretación de resultados de laboratorio o el apoyo en organización de salud), cada usuario o colaborador debe configurar su propia **Google AI Studio API Key**.

### Español

1. **Obtén tu clave gratuita:**
   * Ingresa a [Google AI Studio](https://aistudio.google.com/) con tu cuenta de Google.
   * Crea o selecciona un proyecto y genera una nueva **API Key** en la sección *API keys*.
   * El nivel gratuito (*Free tier*) permite probar y usar modelos compatibles sin necesidad de configurar facturación desde el primer minuto (sujeto a los límites de cuota vigentes por proyecto).
2. **Configura la clave en tu entorno local:**
   * Copia el archivo de ejemplo de variables de entorno (por ejemplo, `.env.example` a `.env`) o configúrala en la pantalla de ajustes / variables de entorno de tu ejecución en Flutter.
   * Asigna tu clave sin compartirla ni subirla al repositorio:
     ```bash
     GEMINI_API_KEY=tu_api_key_de_google_ai_studio
     ```
3. **Seguridad y privacidad:**
   * **Nunca** subas archivos `.env` ni claves reales a GitHub (`Jaav07/TuAliado`).
   * Al tratarse de información sensible de salud, evita enviar datos personales identificables innecesarios y revisa las políticas de privacidad del servicio de IA que utilices.

---

### English

1. **Get your free API key:**
   * Go to [Google AI Studio](https://aistudio.google.com/) and sign in with your Google account.
   * Create or select a project and generate a new **API Key** under *API keys*.
   * The free tier lets you get started without setting up billing upfront (subject to current per-project rate and usage limits).
2. **Configure the key locally:**
   * Copy your environment template (for example, from `.env.example` to `.env`) or set the key in your local environment / app configuration before running Flutter.
   * Add your key without committing it to version control:
     ```bash
     GEMINI_API_KEY=your_google_ai_studio_api_key
     ```
3. **Security & privacy:**
   * **Never** commit `.env` files or live API keys to GitHub (`Jaav07/TuAliado`).
   * Because medical records are sensitive, avoid including unnecessary personally identifiable details and review the data privacy terms of your AI provider.
