package com.warfox.agent

import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import kotlin.math.abs

class StopOverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var bubble: TextView? = null
    private var layoutParams: WindowManager.LayoutParams? = null
    private var downX = 0f
    private var downY = 0f
    private var startX = 0
    private var startY = 0
    private var dragged = false

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val view = TextView(this).apply {
            text = "● WARFOX\nإيقاف طارئ"
            textSize = 13f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            setPadding(18, 12, 18, 12)
            background = GradientDrawable().apply {
                setColor(Color.rgb(190, 38, 48))
                cornerRadius = 48f
                setStroke(2, Color.WHITE)
            }
            contentDescription = "اسحب لتحريك زر WARFOX، واضغط لإيقاف الوكيل"
            isClickable = true
            isFocusable = true
        }
        val type = if (Build.VERSION.SDK_INT >= 26)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else WindowManager.LayoutParams.TYPE_PHONE
        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.TOP or Gravity.START; x = 12; y = 220 }

        view.setOnTouchListener { target, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX
                    downY = event.rawY
                    startX = lp.x
                    startY = lp.y
                    dragged = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - downX).toInt()
                    val dy = (event.rawY - downY).toInt()
                    if (abs(dx) > 6 || abs(dy) > 6) dragged = true
                    if (dragged) {
                        lp.x = (startX + dx).coerceAtLeast(0)
                        lp.y = (startY + dy).coerceAtLeast(0)
                        try { windowManager?.updateViewLayout(view, lp) } catch (_: Exception) { }
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!dragged) target.performClick()
                    true
                }
                else -> false
            }
        }
        view.setOnClickListener {
            sendBroadcast(Intent(this, StopCaptureReceiver::class.java)
                .setAction(AgentStatusService.ACTION_STOP_ALL))
        }
        bubble = view
        layoutParams = lp
        windowManager?.addView(view, lp)
    }

    override fun onDestroy() {
        bubble?.let { try { windowManager?.removeView(it) } catch (_: Exception) { } }
        bubble = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
