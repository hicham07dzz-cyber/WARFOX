package com.warfox.agent

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder

class ScreenCaptureService : Service() {
    private var projection: MediaProjection? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createChannel()
        startForeground(41, notification())
        val resultCode = intent?.getIntExtra("resultCode", 0) ?: 0
        val data = intent?.getParcelableExtra<Intent>("captureData")
        if (resultCode == 0 || data == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        val manager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        projection = manager.getMediaProjection(resultCode, data)
        // Capture pipeline is deliberately not started until the user enables a task in the UI.
        return START_NOT_STICKY
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            val channel = NotificationChannel("warfox_capture", "WARFOX screen session", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun notification(): Notification =
        if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, "warfox_capture")
            .setContentTitle("WARFOX AI AGENT")
            .setContentText("مشاركة الشاشة نشطة — يمكنك إيقافها من التطبيق.")
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .build()
        else Notification.Builder(this).setContentTitle("WARFOX AI AGENT")
            .setSmallIcon(android.R.drawable.ic_menu_view).build()

    override fun onDestroy() {
        projection?.stop()
        projection = null
        super.onDestroy()
    }
    override fun onBind(intent: Intent?): IBinder? = null
}
