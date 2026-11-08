package com.warfox.agent
import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class AiProviderClient(private val context: Context) {
    fun complete(prompt: String): String {
        val endpoint = AiProviderStore.endpoint(context).trimEnd('/')
        val model = AiProviderStore.model(context)
        val key = AiProviderStore.apiKey(context)
        require(endpoint.startsWith("https://") && key.isNotBlank() && model.isNotBlank()) { "أكمل إعدادات مزود الذكاء الاصطناعي." }
        val connection = URL("$endpoint/chat/completions").openConnection() as HttpURLConnection
        connection.requestMethod = "POST"
        connection.connectTimeout = 15000
        connection.readTimeout = 60000
        connection.doOutput = true
        connection.setRequestProperty("Authorization", "Bearer $key")
        connection.setRequestProperty("Content-Type", "application/json; charset=utf-8")
        val body = JSONObject().put("model", model).put("messages", JSONArray()
            .put(JSONObject().put("role", "system").put("content", "أنت WARFOX AI AGENT. أجب بالعربية بوضوح. لا تدّع تنفيذ أي إجراء على الهاتف أو تعديل الملفات ما لم تؤكده أداة التنفيذ. اطلب الموافقة قبل التغييرات المهمة."))
            .put(JSONObject().put("role", "user").put("content", prompt))).put("temperature", 0.3)
        try {
            connection.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
            val code = connection.responseCode
            val stream = if (code in 200..299) connection.inputStream else connection.errorStream
            val raw = stream?.bufferedReader()?.use { it.readText() }.orEmpty()
            if (code !in 200..299) {
                val detail = try { JSONObject(raw).optJSONObject("error")?.optString("message") } catch (_: Exception) { null }
                throw IllegalStateException("HTTP $code: " + (detail?.take(400) ?: raw.take(400)))
            }
            val choices = JSONObject(raw).optJSONArray("choices") ?: error("استجابة المزود لا تحتوي choices.")
            val answer = choices.optJSONObject(0)?.optJSONObject("message")?.optString("content").orEmpty()
            if (answer.isBlank()) error("عاد النموذج برد فارغ.")
            return answer
        } finally { connection.disconnect() }
    }
}
