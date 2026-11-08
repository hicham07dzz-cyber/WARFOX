package com.warfox.agent

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.view.ViewGroup

class MainActivity : Activity() {
    private lateinit var status: TextView
    private val captureRequest = 4102

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(28, 36, 28, 24)
        }
        status = TextView(this).apply {
            text = "WARFOX AI AGENT\n\nمساعدك الذكي للهاتف وGodot. كل صلاحية تحتاج موافقتك."
            textSize = 18f
        }
        root.addView(status, LinearLayout.LayoutParams(-1, 0, 1f))
        root.addView(actionButton("تفعيل خدمة التحكم") { openAccessibilitySettings() })
        root.addView(actionButton("السماح بزر الإيقاف العائم") { requestOverlayPermission() })
        root.addView(actionButton("بدء مشاركة الشاشة") { requestScreenCapture() })
        root.addView(actionButton("إيقاف الوكيل") {
            stopService(Intent(this, ScreenCaptureService::class.java))
            stopService(Intent(this, StopOverlayService::class.java))
            status.text = "تم إرسال طلب الإيقاف."
        })
        setContentView(root)
    }

    private fun actionButton(label: String, action: () -> Unit) =
        Button(this).apply {
            text = label
            setOnClickListener { action() }
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

    private fun openAccessibilitySettings() {
        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
    }

    private fun requestOverlayPermission() {
        if (!Settings.canDrawOverlays(this)) {
            startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
        } else {
            startService(Intent(this, StopOverlayService::class.java))
            status.text = "زر الإيقاف العائم نشط."
        }
    }

    private fun requestScreenCapture() {
        val manager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(manager.createScreenCaptureIntent(), captureRequest)
    }

    @Deprecated("Legacy result callback retained for broad device compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == captureRequest && resultCode == RESULT_OK && data != null) {
            val service = Intent(this, ScreenCaptureService::class.java).apply {
                putExtra("resultCode", resultCode)
                putExtra("captureData", data)
            }
            startForegroundService(service)
            status.text = "مشاركة الشاشة بدأت بموافقتك. اضغط إيقاف لإنهائها."
        }
    }
}
