package com.warfox.agent
import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.text.InputType
import android.view.Gravity
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.util.concurrent.Executors

class AiProviderSettingsActivity : Activity() {
    private lateinit var endpoint: EditText
    private lateinit var model: EditText
    private lateinit var apiKey: EditText
    private lateinit var status: TextView
    private val executor = Executors.newSingleThreadExecutor()
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.rgb(12, 17, 25)
        window.navigationBarColor = Color.rgb(12, 17, 25)
        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(22), dp(24), dp(22), dp(20)); setBackgroundColor(Color.rgb(12, 17, 25)) }
        root.addView(TextView(this).apply { text = "WARFOX  /  AI CORE"; textSize = 22f; setTextColor(Color.rgb(255, 139, 48)); gravity = Gravity.CENTER_VERTICAL })
        root.addView(TextView(this).apply { text = "إعداد مزود الذكاء الاصطناعي"; textSize = 18f; setTextColor(Color.WHITE); setPadding(0, dp(10), 0, dp(6)) })
        root.addView(TextView(this).apply { text = "يدعم OpenAI-compatible مثل OpenAI وGroq وOpenRouter وأي مزود يوفّر /chat/completions. المفتاح يُشفّر محلياً عبر Android Keystore ولا يُرفع إلى GitHub."; textSize = 13f; setTextColor(Color.rgb(175, 190, 207)); setPadding(0, 0, 0, dp(14)) })
        endpoint = addField(root, "رابط API الأساسي", AiProviderStore.endpoint(this), "https://api.openai.com/v1")
        model = addField(root, "اسم النموذج", AiProviderStore.model(this), "مثال: llama-3.3-70b-versatile")
        apiKey = addField(root, "مفتاح API", "", "الصق مفتاحك هنا")
        apiKey.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        status = TextView(this).apply { text = if (AiProviderStore.isConfigured(this@AiProviderSettingsActivity)) "إعداد محفوظ. أدخل مفتاحاً جديداً لاستبداله." else "لم يتم إعداد مزود بعد."; textSize = 13f; setTextColor(Color.rgb(220, 225, 235)); setPadding(0, dp(12), 0, dp(8)) }
        root.addView(status)
        root.addView(button("حفظ الإعدادات المشفرة", Color.rgb(238, 119, 37)) { save() })
        root.addView(button("اختبار الاتصال الحقيقي", Color.rgb(42, 112, 88)) { testConnection() })
        root.addView(button("حذف المفتاح والإعدادات", Color.rgb(145, 52, 57)) { AiProviderStore.clear(this); apiKey.setText(""); status.text = "حُذفت إعدادات المزود من الجهاز." })
        root.addView(button("رجوع", Color.rgb(47, 63, 82)) { finish() })
        setContentView(ScrollView(this).apply { addView(root) })
    }
    private fun addField(root: LinearLayout, label: String, value: String, hintText: String): EditText {
        root.addView(TextView(this).apply { text = label; textSize = 13f; setTextColor(Color.rgb(255, 153, 67)); setPadding(0, dp(8), 0, dp(5)) })
        return EditText(this).apply {
            setText(value); hint = hintText; setHintTextColor(Color.rgb(125, 139, 158)); setTextColor(Color.WHITE); textSize = 14f; setSingleLine(true)
            setPadding(dp(12), dp(8), dp(12), dp(8)); setBackgroundColor(Color.rgb(31, 41, 56))
            root.addView(this, LinearLayout.LayoutParams(-1, dp(52)))
        }
    }
    private fun button(label: String, color: Int, action: () -> Unit) = Button(this).apply {
        text = label; isAllCaps = false; setTextColor(Color.WHITE); backgroundTintList = android.content.res.ColorStateList.valueOf(color); setOnClickListener { action() }
    }
    private fun save() {
        try { AiProviderStore.save(this, endpoint.text.toString(), model.text.toString(), apiKey.text.toString()); apiKey.setText(""); status.text = "حُفظ المفتاح مشفراً محلياً. اضغط اختبار الاتصال للتحقق." }
        catch (e: Exception) { status.text = "تعذر الحفظ: " + e.message }
    }
    private fun testConnection() {
        if (apiKey.text.toString().isNotBlank()) { try { save() } catch (e: Exception) { status.text = "تعذر الحفظ: " + e.message; return } }
        status.text = "جارٍ اختبار اتصال حقيقي..."
        executor.execute {
            try { val answer = AiProviderClient(this).complete("أجب بكلمة واحدة فقط: WARFOX-OK"); runOnUiThread { status.text = "نجح الاتصال. رد النموذج: " + answer.take(160) } }
            catch (e: Exception) { runOnUiThread { status.text = "فشل الاتصال: " + e.message } }
        }
    }
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
}
