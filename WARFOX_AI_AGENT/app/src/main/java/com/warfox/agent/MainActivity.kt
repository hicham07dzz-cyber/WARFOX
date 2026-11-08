package com.warfox.agent

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import java.util.concurrent.Executors

class MainActivity : Activity() {
    private lateinit var status: TextView
    private lateinit var prompt: EditText
    private val captureRequest = 4102
    private val executor = Executors.newSingleThreadExecutor()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(24, 28, 24, 20)
        }
        val heading = TextView(this).apply {
            text = "WARFOX AI AGENT"
            textSize = 24f
        }
        prompt = EditText(this).apply {
            hint = "اكتب ما تريد من الوكيل تنفيذه..."
            minLines = 3
            gravity = android.view.Gravity.TOP
        }
        status = TextView(this).apply {
            text = "مساعدك الذكي للهاتف وGodot. لا ينفذ أي تعديل على الملفات دون موافقتك."
            textSize = 15f
        }
        root.addView(heading)
        root.addView(prompt, LinearLayout.LayoutParams(-1, 0, 1f))
        root.addView(actionButton("إرسال المهمة إلى محرك WARFOX") { submitTask() })
        root.addView(status)
        root.addView(actionButton("تفعيل خدمة التحكم") { openAccessibilitySettings() })
        root.addView(actionButton("السماح بزر الإيقاف العائم") { requestOverlayPermission() })
        root.addView(actionButton("بدء مشاركة الشاشة") { requestScreenCapture() })
        root.addView(actionButton("إيقاف الوكيل") {
            AgentRuntime.stop()
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

    private fun submitTask() {
        val message = prompt.text.toString().trim()
        if (message.isEmpty()) {
            status.text = "اكتب وصف المهمة أولاً."
            return
        }
        if (message.length > 3000) {
            status.text = "الحد الأقصى للوصف 3000 حرف."
            return
        }
        status.text = "جارٍ إرسال المهمة..."
        executor.execute {
            try {
                val api = TaskApi()
                val created = api.createTask(message)
                if (!created.optBoolean("ok")) throw IllegalStateException(created.optString("error", "تعذر إنشاء المهمة"))
                val taskId = created.getString("task_id")
                val started = api.startWorker(taskId)
                runOnUiThread {
                    status.text = "تم إنشاء المهمة: $taskId\nبدء العامل: ${started.optString("status", "تم الإرسال")}\nيمكنك متابعة النتائج من محرك WARFOX."
                }
            } catch (error: Exception) {
                runOnUiThread { status.text = "تعذر الاتصال بالمحرك: ${error.message}\nتأكد أن خادم Termux يعمل على هذا الهاتف." }
            }
        }
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

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }
}
