package com.warfox.smartcut

import android.app.Activity
import android.os.Bundle
import android.content.Intent
import android.net.Uri
import android.graphics.Color
import android.view.Gravity
import android.widget.*
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : Activity() {
    private var reference: Uri? = null
    private val clips = mutableListOf<Uri>()
    private lateinit var status: TextView
    private lateinit var duration: EditText
    private val pickReference = 10
    private val pickClips = 11
    private val savePlan = 12

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.rgb(15, 18, 24)
        window.navigationBarColor = Color.rgb(15, 18, 24)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(24, 36, 24, 24)
            setBackgroundColor(Color.rgb(15, 18, 24))
        }
        fun text(value: String, size: Float, color: Int = Color.WHITE) =
            TextView(this).apply {
                this.text = value
                textSize = size
                setTextColor(color)
                setPadding(0, 10, 0, 10)
            }
        root.addView(text("SMARTCUT AI", 27f).apply { gravity = Gravity.CENTER })
        root.addView(text("مختبر المونتاج الذكي", 16f, Color.LTGRAY).apply { gravity = Gravity.CENTER })
        fun action(label: String, callback: () -> Unit) {
            root.addView(Button(this).apply { text = label; setOnClickListener { callback() } })
        }
        action("اختيار الفيديو المرجعي") { choose(pickReference, false) }
        action("اختيار مقاطع الفيديو") { choose(pickClips, true) }
        root.addView(text("مدة الفيديو النهائي بالثواني", 15f))
        duration = EditText(this).apply {
            setText("30"); setTextColor(Color.WHITE); setHintTextColor(Color.GRAY); inputType = 2
        }
        root.addView(duration)
        status = text("اختر فيديو مرجعياً ومقاطعك للبدء.", 14f, Color.LTGRAY)
        root.addView(status)
        action("إنشاء خطة مونتاج أولية") { createPlan() }
        action("تصدير ملف الخطة JSON") { exportPlan() }
        root.addView(text(
            "تنبيه: هذه نسخة Android أولية. اختيار الملفات وخطة JSON يعملان محلياً؛ تحليل أسلوب المرجع بالذكاء الاصطناعي وتطبيق المؤثرات وإخراج فيديو نهائي لم تُنفّذ بعد.",
            13f, Color.rgb(255, 190, 100)
        ))
        setContentView(ScrollView(this).apply { addView(root) })
    }

    private fun choose(request: Int, multiple: Boolean) {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "video/*"
            if (multiple) putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        }
        startActivityForResult(intent, request)
    }

    @Deprecated("Deprecated Android callback kept for broad device compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode != RESULT_OK || data == null) return
        when (requestCode) {
            pickReference -> {
                reference = data.data
                reference?.let {
                    try { contentResolver.takePersistableUriPermission(it, Intent.FLAG_GRANT_READ_URI_PERMISSION) } catch (_: Exception) {}
                }
            }
            pickClips -> {
                val permission = Intent.FLAG_GRANT_READ_URI_PERMISSION
                data.clipData?.let { cd ->
                    for (i in 0 until cd.itemCount) {
                        val uri = cd.getItemAt(i).uri
                        clips.add(uri)
                        try { contentResolver.takePersistableUriPermission(uri, permission) } catch (_: Exception) {}
                    }
                } ?: data.data?.let {
                    clips.add(it)
                    try { contentResolver.takePersistableUriPermission(it, permission) } catch (_: Exception) {}
                }
            }
        }
        val refText = if (reference == null) "غير محدد" else "تم الاختيار"
        status.text = "المرجع: " + refText + "\nعدد المقاطع: " + clips.size
    }

    private fun buildPlan(): JSONObject {
        val seconds = duration.text.toString().toIntOrNull()?.coerceIn(5, 600) ?: 30
        val items = JSONArray()
        val perClip = if (clips.isEmpty()) 0.0 else seconds.toDouble() / clips.size
        clips.forEachIndexed { index, uri ->
            items.put(JSONObject().apply {
                put("index", index + 1)
                put("uri", uri.toString())
                put("proposed_duration_seconds", perClip)
                put("note", "اقتراح زمني أولي؛ لم يتم تحليل محتوى المشهد")
            })
        }
        return JSONObject().apply {
            put("app", "SmartCut AI")
            put("version", "0.1.0")
            put("reference_uri", reference?.toString() ?: JSONObject.NULL)
            put("target_duration_seconds", seconds)
            put("clips", items)
            put("analysis_status", "metadata_only_prototype")
        }
    }

    private fun createPlan() {
        if (reference == null || clips.isEmpty()) {
            status.text = "اختر الفيديو المرجعي ومقطعاً واحداً على الأقل."
            return
        }
        status.text = "تم تجهيز خطة أولية لـ " + clips.size + " مقطعاً. لم يبدأ تحليل AI أو إخراج الفيديو."
    }

    private fun exportPlan() {
        if (reference == null || clips.isEmpty()) {
            status.text = "اختر الفيديو المرجعي ومقطعاً واحداً على الأقل أولاً."
            return
        }
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
            putExtra(Intent.EXTRA_TITLE, "smartcut-edit-plan.json")
        }
        startActivityForResult(intent, savePlan)
    }
}
