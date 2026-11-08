package com.warfox.agent

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import java.util.concurrent.Executors

class GoogleAccountActivity : Activity() {
    private lateinit var clientId: EditText
    private lateinit var status: TextView
    private val executor = Executors.newSingleThreadExecutor()
    private val prefs by lazy { getSharedPreferences("warfox_google_account", MODE_PRIVATE) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.rgb(12, 17, 25)
        window.navigationBarColor = Color.rgb(12, 17, 25)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(22), dp(24), dp(22), dp(20))
            setBackgroundColor(Color.rgb(12, 17, 25))
        }
        root.addView(TextView(this).apply {
            text = "WARFOX  /  ACCOUNT"; textSize = 22f
            setTextColor(Color.rgb(255, 139, 48))
        })
        root.addView(TextView(this).apply {
            text = "ربط حساب Google"; textSize = 20f
            setTextColor(Color.WHITE); setPadding(0, dp(12), 0, dp(8))
        })
        root.addView(TextView(this).apply {
            text = "أدخل OAuth Web Client ID من Google Cloud Console مرة واحدة. بعد تسجيل الدخول نحفظ اسمك وبريدك وصورة الحساب محلياً على الهاتف. لا نرسل رمز الدخول إلى GitHub."
            textSize = 13f; setTextColor(Color.rgb(180, 192, 208))
        })
        clientId = EditText(this).apply {
            hint = "OAuth Web Client ID"
            setText(prefs.getString("web_client_id", "") ?: "")
            setTextColor(Color.WHITE); setHintTextColor(Color.GRAY); singleLine = true
            setPadding(dp(12), dp(8), dp(12), dp(8)); setBackgroundColor(Color.rgb(31, 41, 56))
        }
        root.addView(clientId, LinearLayout.LayoutParams(-1, dp(52)))
        status = TextView(this).apply {
            text = accountText(); setTextColor(Color.rgb(220, 225, 235))
            textSize = 14f; setPadding(0, dp(14), 0, dp(12))
        }
        root.addView(status)
        root.addView(button("حفظ Client ID", Color.rgb(55, 75, 101)) {
            val id = clientId.text.toString().trim()
            if (!id.endsWith(".apps.googleusercontent.com")) {
                status.text = "Client ID غير صحيح. استخدم OAuth Web Client ID من Google Cloud."
            } else {
                prefs.edit().putString("web_client_id", id).apply()
                status.text = "تم حفظ Client ID محلياً. يمكنك الآن تسجيل الدخول."
            }
        })
        root.addView(button("المتابعة باستخدام Google", Color.rgb(238, 119, 37)) { signIn() })
        root.addView(button("تسجيل الخروج من هذا التطبيق", Color.rgb(145, 52, 57)) {
            prefs.edit().remove("name").remove("email").remove("photo").remove("google_id").apply()
            status.text = "تم حذف ملف الحساب المحلي من WARFOX."
        })
        root.addView(button("رجوع", Color.rgb(47, 63, 82)) { finish() })
        setContentView(ScrollView(this).apply { addView(root) })
    }

    private fun signIn() {
        val id = clientId.text.toString().trim()
        if (!id.endsWith(".apps.googleusercontent.com")) {
            status.text = "أدخل OAuth Web Client ID الصحيح أولاً."
            return
        }
        prefs.edit().putString("web_client_id", id).apply()
        status.text = "جارٍ فتح نافذة Google الآمنة..."
        val option = GetGoogleIdOption.Builder()
            .setFilterByAuthorizedAccounts(false)
            .setServerClientId(id)
            .setAutoSelectEnabled(false)
            .build()
        val request = GetCredentialRequest.Builder().addCredentialOption(option).build()
        try {
            CredentialManager.create(this).getCredentialAsync(
                this, request, null, executor,
                object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
                    override fun onResult(result: GetCredentialResponse) {
                        try {
                            val credential = result.credential
                            if (credential !is CustomCredential ||
                                credential.type != GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                                runOnUiThread { status.text = "نوع بيانات اعتماد Google غير مدعوم." }
                                return
                            }
                            val google = GoogleIdTokenCredential.createFrom(credential.data)
                            prefs.edit()
                                .putString("google_id", google.id)
                                .putString("name", google.displayName ?: "")
                                .putString("email", google.id)
                                .putString("photo", google.profilePictureUri?.toString() ?: "")
                                .apply()
                            runOnUiThread {
                                status.text = "تم تسجيل الدخول إلى Google وحفظ الملف المحلي.\n" +
                                    "الاسم: " + (google.displayName ?: "غير متاح") + "\n" +
                                    "البريد: " + google.id + "\n\n" +
                                    "مزامنة البيانات بين الأجهزة تحتاج خادم حسابات آمن؛ التخزين الحالي محلي على هذا الهاتف."
                            }
                        } catch (e: Exception) {
                            runOnUiThread { status.text = "تعذر قراءة بيانات Google: " + e.message }
                        }
                    }
                    override fun onError(error: GetCredentialException) {
                        runOnUiThread { status.text = "تعذر تسجيل الدخول: " + error.message }
                    }
                }
            )
        } catch (e: Exception) {
            status.text = "تعذر بدء Google Sign-In: " + e.message
        }
    }

    private fun accountText(): String {
        val email = prefs.getString("email", null)
        return if (email.isNullOrBlank()) "لا يوجد حساب Google مربوط حالياً."
        else "الحساب المحفوظ محلياً: " + (prefs.getString("name", "") ?: "") + "\n" + email
    }
    private fun button(label: String, color: Int, action: () -> Unit) = Button(this).apply {
        text = label; isAllCaps = false; setTextColor(Color.WHITE)
        backgroundTintList = android.content.res.ColorStateList.valueOf(color)
        setOnClickListener { action() }
    }
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
}
