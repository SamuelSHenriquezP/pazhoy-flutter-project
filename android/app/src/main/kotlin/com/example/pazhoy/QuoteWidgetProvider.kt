package com.example.pazhoy

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.io.File
import kotlin.random.Random

/**
 * Widget de pantalla de inicio para PazHoy.
 *
 * Modos:
 *  - "daily"     → muestra la frase del día (actualizada desde Flutter)
 *  - "favorites" → rota aleatoriamente entre las frases favoritas del usuario
 *  - "pinned"    → muestra la frase fijada manualmente por el usuario desde la app
 *
 * Soporta la personalización idéntica a la app en sí misma:
 *  - Color de fondo y color de texto.
 *  - Imagen de fondo personalizada del almacenamiento local.
 *  - Opacidad / overlay de color.
 *  - Alineación de texto y tamaño de fuente dinámico.
 */
class QuoteWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_REFRESH = "com.example.pazhoy.WIDGET_REFRESH"
        const val PREFS_NAME = "HomeWidgetPreferences"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, QuoteWidgetProvider::class.java)
            )
            for (id in ids) {
                updateWidget(context, manager, id, forceRotate = true)
            }
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        forceRotate: Boolean = false
    ) {
        val prefs: SharedPreferences =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        val mode = prefs.getString("widget_mode", "daily") ?: "daily"

        val (text, author) = when (mode) {
            "favorites" -> {
                val json = prefs.getString("widget_favorites_json", null)
                getRandomFavorite(json) ?: Pair(
                    prefs.getString("widget_daily_text", "Abre la app para cargar frases.") ?: "",
                    prefs.getString("widget_daily_author", "") ?: ""
                )
            }
            else -> {
                Pair(
                    prefs.getString("widget_daily_text", "Abre la app para cargar frases.") ?: "",
                    prefs.getString("widget_daily_author", "") ?: ""
                )
            }
        }

        val views = RemoteViews(context.packageName, R.layout.quote_widget)
        views.setTextViewText(R.id.widget_quote_text, text)
        views.setTextViewText(
            R.id.widget_quote_author,
            if (author.isNotEmpty()) "— $author" else ""
        )

        // --- Personalización del Estilo ---
        val defaultBgColor = android.graphics.Color.parseColor("#1A1A2E") // Azul oscuro por defecto de la app
        val defaultTextColor = android.graphics.Color.WHITE

        // Cargar variables de estilo desde Flutter (StyleProvider)
        val bgColor = prefs.getInt("widget_bg_color", defaultBgColor)
        val textColor = prefs.getInt("widget_text_color", defaultTextColor)
        val bgImage = prefs.getString("widget_bg_image", null)
        val bgOpacity = prefs.getFloat("widget_bg_opacity", 0.0f)
        val fontSize = prefs.getFloat("widget_font_size", 16.0f)
        val textAlign = prefs.getInt("widget_text_align", 17) // 17 es Gravity.CENTER

        // 1. Aplicar colores de texto con su respectivo canal de opacidad
        views.setTextColor(R.id.widget_quote_text, textColor)
        views.setTextColor(R.id.widget_quote_author, (textColor and 0x00FFFFFF) or (0xCC shl 24)) // 80% opacity
        views.setTextColor(R.id.widget_quote_mark, (textColor and 0x00FFFFFF) or (0x80 shl 24)) // 50% opacity

        // 2. Aplicar alineación de texto y tamaño de fuente
        views.setInt(R.id.widget_quote_text, "setGravity", textAlign)
        val clampedFontSize = fontSize.coerceIn(12f, 22f) // Mantener tamaño balanceado en widget
        views.setTextViewTextSize(R.id.widget_quote_text, TypedValue.COMPLEX_UNIT_SP, clampedFontSize)

        // 3. Aplicar color de fondo
        if (bgImage != null && bgImage.isNotEmpty()) {
            views.setInt(R.id.widget_root, "setBackgroundColor", android.graphics.Color.TRANSPARENT)
        } else {
            views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)
        }

        // 4. Aplicar imagen de fondo
        if (bgImage != null && bgImage.isNotEmpty()) {
            val file = File(bgImage)
            if (file.exists()) {
                try {
                    val bitmap = android.graphics.BitmapFactory.decodeFile(file.absolutePath)
                    if (bitmap != null) {
                        views.setImageViewBitmap(R.id.widget_background_image, bitmap)
                        views.setViewVisibility(R.id.widget_background_image, View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.widget_background_image, View.GONE)
                    }
                } catch (e: Exception) {
                    views.setViewVisibility(R.id.widget_background_image, View.GONE)
                }
            } else {
                views.setViewVisibility(R.id.widget_background_image, View.GONE)
            }
        } else {
            views.setViewVisibility(R.id.widget_background_image, View.GONE)
        }

        // 5. Aplicar capa de opacidad (overlay)
        if (bgOpacity > 0.0f) {
            val overlayBaseColor = if (bgImage != null && bgImage.isNotEmpty()) bgColor else android.graphics.Color.WHITE
            val alpha = (bgOpacity * 255).toInt().coerceIn(0, 255)
            val overlayColor = (alpha shl 24) or (overlayBaseColor and 0x00FFFFFF)
            views.setInt(R.id.widget_background_overlay, "setBackgroundColor", overlayColor)
            views.setViewVisibility(R.id.widget_background_overlay, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_background_overlay, View.GONE)
        }

        // --- Acciones del Widget ---
        // Tap en el cuerpo del widget → Abre la app
        val openAppIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }

        val openAppPending = PendingIntent.getActivity(
            context, 0, openAppIntent ?: Intent(),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_quote_text, openAppPending)
        views.setOnClickPendingIntent(R.id.widget_quote_mark, openAppPending)
        views.setOnClickPendingIntent(R.id.widget_quote_author, openAppPending)

        // Tap en botón refrescar → Rota frase (modo favoritos)
        val refreshIntent = Intent(context, QuoteWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
        }
        val refreshPending = PendingIntent.getBroadcast(
            context, 1, refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_refresh_button, refreshPending)

        // Mostrar botón de refrescar sólo en modo "favoritos"
        views.setViewVisibility(
            R.id.widget_refresh_button,
            if (mode == "favorites") View.VISIBLE else View.GONE
        )

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun getRandomFavorite(json: String?): Pair<String, String>? {
        if (json.isNullOrBlank()) return null
        return try {
            val array = JSONArray(json)
            if (array.length() == 0) return null
            val item = array.getJSONObject(Random.nextInt(array.length()))
            val text = item.optString("text", "")
            val author = item.optString("author", "")
            if (text.isEmpty()) null else Pair(text, author)
        } catch (e: Exception) {
            null
        }
    }
}
