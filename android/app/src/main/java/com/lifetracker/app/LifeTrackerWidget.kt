package com.lifetracker.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.lifetracker.app.R

class LifeTrackerWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.life_tracker_widget)

            // Upcoming plan data saved by Dart via HomeWidget.saveWidgetData()
            val title = widgetData.getString("upcoming_title", "No upcoming plans") ?: "No upcoming plans"
            val date  = widgetData.getString("upcoming_date",  "") ?: ""
            val count = widgetData.getString("upcoming_count", "0") ?: "0"
            val cat   = widgetData.getString("upcoming_category", "") ?: ""

            views.setTextViewText(R.id.widget_upcoming_title, title)
            views.setTextViewText(R.id.widget_upcoming_date,  date)
            views.setTextViewText(R.id.widget_upcoming_count, "$count upcoming")
            views.setTextViewText(R.id.widget_category,       cat)

            // Launch app on tap
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (intent != null) {
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context, 0, intent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
