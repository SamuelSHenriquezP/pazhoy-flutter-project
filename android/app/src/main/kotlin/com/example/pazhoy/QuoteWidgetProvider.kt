package com.example.pazhoy

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import kotlin.random.Random

/**
 * Widget de pantalla de inicio para PazHoy.
 * Solo muestra texto (frase + autor), sin imágenes de fondo.
 */
class QuoteWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_REFRESH = "com.example.pazhoy.WIDGET_REFRESH"

        private const val DEFAULT_BG_COLOR = 0xCC1A1A2E.toInt()
        private const val DEFAULT_TEXT = "Abre PazHoy para ver la frase del día."
        private const val DEFAULT_AUTHOR = ""
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
                updateWidget(context, manager, id)
            }
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        try {
            val prefs = HomeWidgetPlugin.getData(context)

            android.util.Log.d("QuoteWidget", "Updating widget...")

            val mode = prefs.getString("widget_mode", "daily") ?: "daily"
            val (text, author) = resolveContent(prefs, mode)

            val views = RemoteViews(context.packageName, R.layout.quote_widget)

            // Texto
            views.setTextViewText(R.id.widget_quote_text, text)
            views.setTextViewText(
                R.id.widget_quote_author,
                if (author.isNotEmpty()) "— $author" else ""
            )

            // Colores
            val defaultTextColor = android.graphics.Color.WHITE
            val bgColor = getIntSafe(prefs, "widget_bg_color", DEFAULT_BG_COLOR)
            val textColor = getIntSafe(prefs, "widget_text_color", defaultTextColor)
            val fontSize = getFloatSafe(prefs, "widget_font_size", 14.0f)

            views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)
            views.setTextColor(R.id.widget_quote_text, textColor)
            views.setTextColor(R.id.widget_quote_author, (0xCC shl 24) or (textColor and 0x00FFFFFF))
            views.setTextColor(R.id.widget_quote_mark, (0x80 shl 24) or (textColor and 0x00FFFFFF))

            val clampedFontSize = fontSize.coerceIn(12f, 18f)
            views.setTextViewTextSize(R.id.widget_quote_text, TypedValue.COMPLEX_UNIT_SP, clampedFontSize)

            // Acción al tocar: abrir la app
            val openAppPending = buildOpenAppPendingIntent(context)
            views.setOnClickPendingIntent(R.id.widget_root, openAppPending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
            android.util.Log.d("QuoteWidget", "Widget updated successfully!")

        } catch (e: Exception) {
            android.util.Log.e("QuoteWidget", "ERROR updating widget: ${e.message}", e)
            // Fallback mínimo
            try {
                val safeViews = RemoteViews(context.packageName, R.layout.quote_widget)
                safeViews.setTextViewText(R.id.widget_quote_text, "Abre PazHoy para cargar frases")
                safeViews.setTextViewText(R.id.widget_quote_author, "(toca para abrir la app)")
                safeViews.setInt(R.id.widget_root, "setBackgroundColor", DEFAULT_BG_COLOR)
                safeViews.setOnClickPendingIntent(R.id.widget_root, buildOpenAppPendingIntent(context))
                appWidgetManager.updateAppWidget(appWidgetId, safeViews)
            } catch (e2: Exception) {
                android.util.Log.e("QuoteWidget", "FATAL: Even fallback failed: ${e2.message}", e2)
            }
        }
    }

    private fun buildOpenAppPendingIntent(context: Context): PendingIntent {
        val intent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP }
            ?: Intent()
        return PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun resolveContent(
        prefs: android.content.SharedPreferences,
        mode: String
    ): Pair<String, String> {
        return when (mode) {
            "favorites" -> {
                val json = prefs.getString("widget_favorites_json", null)
                getRandomFavorite(json) ?: Pair(
                    prefs.getString("widget_daily_text", DEFAULT_TEXT) ?: DEFAULT_TEXT,
                    prefs.getString("widget_daily_author", DEFAULT_AUTHOR) ?: DEFAULT_AUTHOR
                )
            }
            "pinned" -> Pair(
                prefs.getString("widget_pinned_text", DEFAULT_TEXT) ?: DEFAULT_TEXT,
                prefs.getString("widget_pinned_author", DEFAULT_AUTHOR) ?: DEFAULT_AUTHOR
            )
            else -> Pair(
                prefs.getString("widget_daily_text", DEFAULT_TEXT) ?: DEFAULT_TEXT,
                prefs.getString("widget_daily_author", DEFAULT_AUTHOR) ?: DEFAULT_AUTHOR
            )
        }
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

    private fun getIntSafe(prefs: android.content.SharedPreferences, key: String, defaultValue: Int): Int {
        return when (val value = prefs.all[key]) {
            is Number -> value.toInt()
            is String -> value.toIntOrNull() ?: defaultValue
            else -> defaultValue
        }
    }

    private fun getFloatSafe(prefs: android.content.SharedPreferences, key: String, defaultValue: Float): Float {
        return when (val value = prefs.all[key]) {
            is Number -> value.toFloat()
            is String -> value.toFloatOrNull() ?: defaultValue
            else -> defaultValue
        }
    }
}
