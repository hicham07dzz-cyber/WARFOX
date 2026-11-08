package com.warfox.agent

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button

class StopOverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var stopButton: Button? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        stopButton = Button(this).apply {
            text = "إيقاف WARFOX"
            setOnClickListener {
                AgentRuntime.stop()
                stopService(Intent(this@StopOverlayService, ScreenCaptureService::class.java))
                stopSelf()
            }
        }
        val type = if (Build.VERSION.SDK_INT >= 26)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else WindowManager.LayoutParams.TYPE_PHONE
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.TOP or Gravity.END; x = 16; y = 180 }
        windowManager?.addView(stopButton, params)
    }

    override fun onDestroy() {
        stopButton?.let { windowManager?.removeView(it) }
        stopButton = null
        super.onDestroy()
    }
    override fun onBind(intent: Intent?): IBinder? = null
}
