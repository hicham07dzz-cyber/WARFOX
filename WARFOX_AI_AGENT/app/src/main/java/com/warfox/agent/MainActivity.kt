package com.warfox.agent

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.ColorStateList
import android.graphics.Color
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.util.concurrent.Executors

class MainActivity : Activity() {
    private lateinit var status: TextView
    private lateinit var prompt: EditText
    private val captureRequest = 4102
    private val executor = Executors.newSingleThreadExecutor()
    private var overlayPermissionPending = false
    private var accessibilitySettingsOpened = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.rgb(15, 20, 29)
        window.navigationBarColor = Color.rgb(15, 20, 29)
        window.decorView.systemUiVisibility = 0

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(22), dp(20), dp(18))
            setBackgroundColor(Color.rgb(15, 20, 29))
        }
        val heading = TextView(this).apply {
            text = "WARFOX AI AGENT"
            textSize = 25f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, 0, 0, dp(8))
        }
        val subtitle = TextView(this).apply {
            text = "اكتب المهمة وسأرسلها إلى محرك WARFOX"
            textSize = 14f
            setTextColor(Color.rgb(185, 195, 210))
            setPadding(0, 0, 0, dp(16))
        }
        prompt = EditText(this).apply {
            hint = "مثال: افتح Godot وساعدني في تطوير اللاعب..."
            setHintTextColor(Color.rgb(145, 155, 170))
            setTextColor(Color.WHITE)
            textSize = 16f
            minLines = 4
            maxLines = 7
            gravity = Gravity.TOP or Gravity.START
            setPadding(dp(14), dp(12), dp(14), dp(12))
            setBackgroundColor(Color.rgb(35, 44, 58))
        }
        status = TextView(this).apply {
            text = "جاهز. مشاركة الشاشة لا تبدأ إلا بعد موافقتك."
            textSize = 14f
            setTextColor(Color.rgb(220, 225, 235))
            setPadding(0, dp(14), 0, dp(10))
        }

        root.addView(heading)
        root.addView(subtitle)
        root.addView(prompt, LinearLayout.LayoutParams(-1, dp(132)))
        root.addView(actionButton("إرسال  ➤", Color.rgb(255, 132, 35)) { submitTask() })
        root.addView(status)
        root.addView(sectionLabel("التحكم والصلاحيات"))
        root.addView(actionButton("تفعيل خدمة إمكانية الوصول", Color.rgb(49, 65, 86)) {
            accessibilitySettingsOpened = true
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
        })
        root.addView(actionButton("تفعيل زر الإيقاف العائم", Color.rgb(49, 65, 86)) {
            if (!Settings.canDrawOverlays(this)) {
                overlayPermissionPending = true
                startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
            } else {
                startOverlay()
            }
        })
        root.addView(actionButton("بدء مشاركة الشاشة", Color.rgb(40, 112, 85)) { requestScreenCapture() })
        root.addView(actionButton("إيقاف مشاركة الشاشة فقط", Color.rgb(160, 94, 35)) {
            stopService(Intent(this, ScreenCaptureService::class.java))
            status.text = "تم إيقاف مشاركة الشاشة."
        })
        root.addView(actionButton("إيقاف الوكيل بالكامل", Color.rgb(155, 49, 55)) {
            AgentRuntime.stop()
            stopService(Intent(this, ScreenCaptureService::class.java))
            stopService(Intent(this, StopOverlayService::class.java))
            status.text = "تم إيقاف التحكم ومشاركة الشاشة والزر العائم."
        })
        root.addView(sectionLabel("التطبيقات"))
        root.addView(actionButton("فتح Godot Editor", Color.rgb(49, 65, 86)) { openGodot() })

        val scroll = ScrollView(this).apply { addView(root) }
        setContentView(scroll)
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    private fun sectionLabel(value: String) = TextView(this).apply {
        text = value
        textSize = 13f
        setTextColor(Color.rgb(255, 153, 65))
        setPadding(0, dp(16), 0, dp(7))
    }

    private fun actionButton(label: String, color: Int, action: () -> Unit) =
        Button(this).apply {
            text = label
            textSize = 14f
            isAllCaps = false
            setTextColor(Color.WHITE)
            backgroundTintList = ColorStateList.valueOf(color)
            minHeight = dp(48)
            setPadding(dp(12), dp(8), dp(12), dp(8))
            setOnClickListener { action() }
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = dp(5) }
        }

    private fun submitTask() {
        val message = prompt.text.toString().trim()
        if (message.isEmpty()) { status.text = "اكتب وصف المهمة أولاً."; return }
        if (message.length > 3000) { status.text = "الحد الأقصى للوصف 3000 حرف."; return }
        status.text = "جارٍ إرسال المهمة..."
        executor.execute {
            try {
                val api = TaskApi()
                val created = api.createTask(message)
                if (!created.optBoolean("ok")) throw IllegalStateException(created.optString("error", "تعذر إنشاء المهمة"))
                val taskId = created.getString("task_id")
                val started = api.startWorker(taskId)
                runOnUiThread {
                    status.text = "تم إرسال المهمة بنجاح.\nرقم المهمة: $taskId\nحالة التشغيل: ${started.optString("status", "تم الإرسال")}"
                }
            } catch (error: Exception) {
                runOnUiThread { status.text = "تعذر الاتصال بمحرك WARFOX: ${error.message}\nتأكد أن خادم Termux يعمل على الهاتف." }
            }
        }
    }

    private fun openAccessibilitySettings() {
        accessibilitySettingsOpened = true
        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
    }

    private fun startOverlay() {
        startService(Intent(this, StopOverlayService::class.java))
        status.text = "زر الإيقاف العائم نشط."
    }

    override fun onResume() {
        super.onResume()
        if (overlayPermissionPending) {
            overlayPermissionPending = false
            if (Settings.canDrawOverlays(this)) startOverlay()
            else status.text = "لم تمنح إذن الظهور فوق التطبيقات. يمكنك المحاولة مجدداً."
        }
        if (accessibilitySettingsOpened) {
            accessibilitySettingsOpened = false
            status.text = "إذا فعّلت خدمة WARFOX في إعدادات إمكانية الوصول، ارجع إلى هنا. إذا كان المفتاح باهتاً، افتح صفحة تفاصيل الخدمة ثم فعّل السماح."
        }
    }

    private fun requestScreenCapture() {
        val manager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(manager.createScreenCaptureIntent(), captureRequest)
    }

    private fun openGodot() {
        val candidates = listOf("org.godotengine.editor.v4", "org.godotengine.editor")
        val launch = candidates.firstNotNullOfOrNull { packageName ->
            packageManager.getLaunchIntentForPackage(packageName)
        }
        if (launch == null) {
            status.text = "لم أجد Godot Editor مثبتاً. ثبّت Godot Editor أولاً."
            return
        }
        status.text = "فتح Godot. يمكنك الرجوع إلى WARFOX من التطبيقات الأخيرة."
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(launch)
    }

    @Deprecated("Legacy result callback retained for broad device compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == captureRequest) {
            if (resultCode == RESULT_OK && data != null) {
                val service = Intent(this, ScreenCaptureService::class.java).apply {
                    putExtra("resultCode", resultCode)
                    putExtra("captureData", data)
                }
                startForegroundService(service)
                status.text = "مشاركة الشاشة بدأت بموافقتك. لإيقافها استخدم زر إيقاف المشاركة أو إشعار WARFOX."
            } else {
                status.text = "لم تبدأ مشاركة الشاشة لأن الإذن لم يُمنح."
            }
        }
    }

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }
}
