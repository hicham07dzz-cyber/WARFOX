package com.warfox.agent

import android.app.Activity
import android.content.Intent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.BitmapFactory
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.os.BatteryManager
import android.os.Debug
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ImageView
import android.widget.ScrollView
import android.widget.Spinner
import android.widget.ArrayAdapter
import android.widget.TextView
import java.util.concurrent.Executors
import org.json.JSONObject

class MainActivity : Activity() {
    private lateinit var status: TextView
    private lateinit var prompt: EditText
    private lateinit var screenPreview: ImageView
    private lateinit var screenDescription: TextView
    private lateinit var taskMemory: TaskMemory
    private lateinit var proposalPreview: TextView
    private lateinit var targetFile: Spinner
    private lateinit var applyPatchButton: Button
    private var currentTaskId: String = ""
    private var proposalReady = false
    private var captureReceiverRegistered = false
    private val captureReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ScreenCaptureService.ACTION_FRAME_CAPTURED -> {
                    val path = intent.getStringExtra(ScreenCaptureService.EXTRA_FILE_PATH) ?: return
                    val width = intent.getIntExtra(ScreenCaptureService.EXTRA_WIDTH, 0)
                    val height = intent.getIntExtra(ScreenCaptureService.EXTRA_HEIGHT, 0)
                    val bitmap = BitmapFactory.decodeFile(path)
                    if (bitmap != null) {
                        screenPreview.setImageBitmap(bitmap)
                        screenPreview.visibility = View.VISIBLE
                        status.text = "نجح التقاط الشاشة محلياً: ${width}×${height}. لم تُرسل الصورة إلى الإنترنت."
                    } else {
                        status.text = "وصلت الصورة لكن تعذر عرضها."
                    }
                }
                ScreenCaptureService.ACTION_CAPTURE_FAILED -> {
                    status.text = "فشل التقاط الشاشة: ${intent.getStringExtra(ScreenCaptureService.EXTRA_ERROR)}"
                }
            }
        }
    }
    private val captureRequest = 4102
    private val executor = Executors.newSingleThreadExecutor()
    private var overlayPermissionPending = false
    private var accessibilitySettingsOpened = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        taskMemory = TaskMemory(this)
        try {
            val statusIntent = Intent(this, AgentStatusService::class.java)
            if (Build.VERSION.SDK_INT >= 26) startForegroundService(statusIntent) else startService(statusIntent)
        } catch (_: Exception) { }
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 903)
        }
        window.statusBarColor = Color.rgb(15, 20, 29)
        window.navigationBarColor = Color.rgb(15, 20, 29)
        window.decorView.systemUiVisibility = 0

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(22), dp(20), dp(18))
            setBackgroundColor(Color.rgb(15, 20, 29))
        }
        val logo = ImageView(this).apply {
            setImageResource(R.drawable.warfox_logo)
            contentDescription = "شعار WARFOX AI AGENT"
            scaleType = ImageView.ScaleType.FIT_CENTER
        }
        root.addView(logo, LinearLayout.LayoutParams(dp(104), dp(104)).apply { gravity = Gravity.CENTER_HORIZONTAL; bottomMargin = dp(8) })
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
        root.addView(actionButton("حساب Google  ●", Color.rgb(65, 91, 125)) { startActivity(Intent(this, GoogleAccountActivity::class.java)) })
        root.addView(actionButton("إعدادات الذكاء الاصطناعي  ⚙", Color.rgb(65, 91, 125)) { startActivity(Intent(this, AiProviderSettingsActivity::class.java)) })
        root.addView(actionButton("إرسال  ➤", Color.rgb(255, 132, 35)) { submitTask() })
        root.addView(actionButton("استكمال آخر مهمة محفوظة", Color.rgb(65, 91, 125)) { resumeLastTask() })
        root.addView(actionButton("عرض سجل المحادثة المحفوظ", Color.rgb(49, 65, 86)) { screenDescription.text = taskMemory.historyText() })
        root.addView(status)
        screenPreview = ImageView(this).apply {
            visibility = View.GONE
            adjustViewBounds = true
            scaleType = ImageView.ScaleType.FIT_CENTER
            setBackgroundColor(Color.rgb(28, 36, 48))
            contentDescription = "آخر صورة شاشة التقطها WARFOX بموافقة المستخدم"
        }
        root.addView(screenPreview, LinearLayout.LayoutParams(-1, dp(220)))
        screenDescription = TextView(this).apply {
            text = "محتوى الشاشة المقروء سيظهر هنا بعد تفعيل إمكانية الوصول."
            textSize = 13f
            setTextColor(Color.rgb(210, 218, 230))
            setPadding(dp(10), dp(10), dp(10), dp(10))
            setBackgroundColor(Color.rgb(28, 36, 48))
        }
        root.addView(screenDescription, LinearLayout.LayoutParams(-1, ViewGroup.LayoutParams.WRAP_CONTENT))
        root.addView(sectionLabel("التحكم والصلاحيات"))
        root.addView(actionButton("قراءة محتوى الشاشة الحالية", Color.rgb(49, 65, 86)) {
            val accessibility = AgentRuntime.accessibilityService
            if (accessibility == null) {
                status.text = "فعّل خدمة إمكانية الوصول أولاً حتى أقرأ أسماء الأزرار والنصوص الظاهرة."
            } else {
                val description = accessibility.describeCurrentScreen()
                screenDescription.text = description
                status.text = "تمت قراءة عناصر الشاشة محلياً. لم يتم النقر أو إرسال المحتوى."
            }
        })
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
        root.addView(actionButton("التقاط صورة للشاشة بموافقتك", Color.rgb(40, 112, 85)) { requestScreenCapture() })
        root.addView(actionButton("إيقاف مشاركة الشاشة فقط", Color.rgb(160, 94, 35)) {
            stopService(Intent(this, ScreenCaptureService::class.java))
            status.text = "تم إيقاف جلسة التقاط الشاشة."
        })
        root.addView(actionButton("إيقاف الوكيل بالكامل", Color.rgb(155, 49, 55)) {
            AgentRuntime.stop()
            stopService(Intent(this, ScreenCaptureService::class.java))
            stopService(Intent(this, StopOverlayService::class.java))
            stopService(Intent(this, AgentStatusService::class.java))
            status.text = "تم إيقاف التحكم ومشاركة الشاشة والزر العائم."
        })

        root.addView(sectionLabel("مساعد Godot — مراجعة التعديلات"))
        targetFile = Spinner(this).apply {
            adapter = ArrayAdapter(this@MainActivity, android.R.layout.simple_spinner_dropdown_item,
                listOf("scripts/player.gd", "scripts/main.gd", "scenes/main.tscn"))
        }
        root.addView(targetFile, LinearLayout.LayoutParams(-1, dp(48)))
        proposalPreview = TextView(this).apply {
            text = "لن يتم تعديل ملفات Godot قبل عرض الاقتراح وموافقتك."
            textSize = 13f
            setTextColor(Color.rgb(220, 225, 235))
            setPadding(dp(10), dp(10), dp(10), dp(10))
            setBackgroundColor(Color.rgb(28, 36, 48))
        }
        root.addView(proposalPreview, LinearLayout.LayoutParams(-1, ViewGroup.LayoutParams.WRAP_CONTENT))
        root.addView(actionButton("عرض اقتراح التعديل", Color.rgb(65, 91, 125)) { loadPatchProposal() })
        applyPatchButton = actionButton("موافقة وتطبيق مع نسخة احتياطية", Color.rgb(40, 112, 85)) { approveAndApplyPatch() }
        applyPatchButton.isEnabled = false
        root.addView(applyPatchButton)
        root.addView(actionButton("تشخيص الذاكرة والبطارية", Color.rgb(49, 65, 86)) { showDiagnostics() })
        root.addView(sectionLabel("التطبيقات"))
        root.addView(actionButton("فتح Godot Engine 4", Color.rgb(49, 65, 86)) { openGodot() })

        val scroll = ScrollView(this).apply { addView(root) }
        setContentView(scroll)
        val filter = android.content.IntentFilter().apply {
            addAction(ScreenCaptureService.ACTION_FRAME_CAPTURED)
            addAction(ScreenCaptureService.ACTION_CAPTURE_FAILED)
        }
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(captureReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        else @Suppress("DEPRECATION") run { registerReceiver(captureReceiver, filter) }
        captureReceiverRegistered = true
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
        taskMemory.saveDraft(message)
        if (AiProviderStore.isConfigured(this)) {
            status.text = "جارٍ إرسال طلب إلى نموذج الذكاء الاصطناعي المحفوظ..."
            executor.execute {
                try {
                    val answer = AiProviderClient(this).complete(message)
                    taskMemory.saveConversation(message, answer)
                    runOnUiThread {
                        screenDescription.text = answer
                        status.text = "وصل رد النموذج بنجاح. تنفيذ اللمس والتحكم ما زال يحتاج ربطاً بمحرك الوكيل."
                    }
                } catch (error: Exception) {
                    runOnUiThread { status.text = "فشل طلب الذكاء الاصطناعي: " + error.message }
                }
            }
            return
        }
        status.text = "لا يوجد مزود API محفوظ؛ سأستخدم محرك Termux المحلي..."
        executor.execute {
            try {
                val api = TaskApi()
                val created = api.createTask(message)
                if (!created.optBoolean("ok")) throw IllegalStateException(created.optString("error", "تعذر إنشاء المهمة"))
                val taskId = created.getString("task_id")
                currentTaskId = taskId
                taskMemory.save(taskId, message, "started")
                val started = api.startWorker(taskId)
                taskMemory.save(taskId, message, started.optString("status", "started"))
                runOnUiThread {
                    status.text = "تم إرسال المهمة بنجاح.\nرقم المهمة: $taskId\nحالة التشغيل: ${started.optString("status", "تم الإرسال")}"
                }
            } catch (error: Exception) {
                runOnUiThread { status.text = "تعذر الاتصال بمحرك WARFOX: ${error.message}\nتأكد أن خادم Termux يعمل على الهاتف." }
            }
        }
    }


    private fun showDiagnostics() {
        val runtime = Runtime.getRuntime()
        val usedMb = (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024)
        val maxMb = runtime.maxMemory() / (1024 * 1024)
        val pssMb = Debug.getPss() / 1024
        val battery = try {
            (getSystemService(BATTERY_SERVICE) as BatteryManager).getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } catch (_: Exception) { -1 }
        screenDescription.text = "استهلاك ذاكرة التطبيق التقريبي: ${usedMb}MB من ${maxMb}MB\nذاكرة العملية PSS: ${pssMb}MB\nالبطارية: ${if (battery >= 0) "$battery%" else "غير متاحة"}\nهذه قراءة لحظية وليست اختبار استهلاك طويل المدى."
        status.text = "اكتمل فحص الموارد اللحظي."
    }
    private fun loadPatchProposal() {
        val taskId = currentTaskId.ifBlank { taskMemory.latest().optString("task_id") }
        if (taskId.isBlank()) {
            status.text = "أرسل مهمة إلى محرك WARFOX أولاً."
            return
        }
        status.text = "جارٍ جلب اقتراح التعديل..."
        executor.execute {
            try {
                val response = TaskApi().getPatchProposal(taskId)
                val patch = response.opt("patch")
                val exists = response.optBoolean("ok") && patch != null && patch != JSONObject.NULL
                runOnUiThread {
                    proposalReady = exists
                    applyPatchButton.isEnabled = exists
                    proposalPreview.text = if (exists) response.toString(2).take(10000)
                        else "لا يوجد اقتراح جاهز لهذه المهمة.\n" + response.toString(2).take(3000)
                    status.text = if (exists) "راجع الاقتراح واختر الملف المستهدف. لن يحدث تعديل قبل ضغط زر الموافقة."
                        else "لم يتم العثور على اقتراح قابل للتطبيق."
                }
            } catch (error: Exception) {
                runOnUiThread {
                    proposalReady = false
                    applyPatchButton.isEnabled = false
                    status.text = "تعذر جلب الاقتراح: ${error.message}"
                }
            }
        }
    }

    private fun approveAndApplyPatch() {
        val taskId = currentTaskId.ifBlank { taskMemory.latest().optString("task_id") }
        val file = targetFile.selectedItem?.toString().orEmpty()
        if (!proposalReady || taskId.isBlank() || file.isBlank()) {
            status.text = "اعرض الاقتراح أولاً واختر الملف قبل الموافقة."
            return
        }
        applyPatchButton.isEnabled = false
        status.text = "جارٍ تطبيق التعديل الذي وافقت عليه وإنشاء النسخة الاحتياطية..."
        executor.execute {
            try {
                val result = TaskApi().applyPatch(taskId, file)
                val ok = result.optBoolean("ok")
                runOnUiThread {
                    proposalReady = false
                    proposalPreview.text = result.toString(2).take(8000)
                    status.text = if (ok) "أبلغ الخادم عن نجاح التطبيق. تحقق من وجود النسخة الاحتياطية قبل متابعة العمل."
                        else "لم يؤكد الخادم نجاح التطبيق؛ راجع تفاصيل النتيجة."
                }
            } catch (error: Exception) {
                runOnUiThread { status.text = "فشل تطبيق الاقتراح: ${error.message}" }
            }
        }
    }

    private fun resumeLastTask() {
        val saved = taskMemory.latest()
        val taskId = saved.optString("task_id")
        val savedPrompt = saved.optString("prompt")
        currentTaskId = taskId
        if (taskId.isBlank()) {
            status.text = if (savedPrompt.isNotBlank()) "آخر وصف محفوظ كمسودة، لكنه لم يحصل على رقم مهمة بعد." else "لا توجد مهمة سابقة محفوظة."
            if (savedPrompt.isNotBlank()) prompt.setText(savedPrompt)
            return
        }
        status.text = "جارٍ استرجاع حالة المهمة السابقة..."
        executor.execute {
            try {
                val result = TaskApi().getTask(taskId)
                val readable = result.toString(2).take(5000)
                taskMemory.save(taskId, savedPrompt, result.optString("status", "retrieved"), readable)
                runOnUiThread {
                    prompt.setText(savedPrompt)
                    screenDescription.text = readable
                    status.text = "تم استرجاع بيانات المهمة $taskId. راجع الحالة قبل طلب استكمال التنفيذ."
                }
            } catch (error: Exception) {
                runOnUiThread {
                    prompt.setText(savedPrompt)
                    status.text = "تعذر الاتصال لاسترجاع المهمة. تم الاحتفاظ بالوصف محلياً: ${error.message}"
                }
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
        val candidates = listOf(
            "org.godotengine.editor.v4",
            "org.godotengine.editor",
            "org.godotengine.editor.v3"
        )
        var launch = candidates.firstNotNullOfOrNull { packageName ->
            packageManager.getLaunchIntentForPackage(packageName)
        }

        // Fallback: discover launcher apps whose visible name contains "Godot".
        if (launch == null) {
            val launcherIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
            val godotApp = packageManager.queryIntentActivities(launcherIntent, 0)
                .firstOrNull { it.loadLabel(packageManager).toString().contains("Godot", ignoreCase = true) }
            if (godotApp != null) {
                launch = packageManager.getLaunchIntentForPackage(godotApp.activityInfo.packageName)
            }
        }

        if (launch == null) {
            status.text = "لم أتمكن من العثور على Godot Engine 4. تأكد أنه مثبت على الهاتف."
            return
        }
        status.text = "جارٍ فتح Godot Engine 4. يمكنك الرجوع إلى WARFOX من التطبيقات الأخيرة."
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
                status.text = "تم منح الإذن. جارٍ التقاط صورة واحدة وحفظها محلياً..."
            } else {
                status.text = "لم تبدأ مشاركة الشاشة لأن الإذن لم يُمنح."
            }
        }
    }

    override fun onDestroy() {
        if (captureReceiverRegistered) unregisterReceiver(captureReceiver)
        executor.shutdownNow()
        super.onDestroy()
    }
}
