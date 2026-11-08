package com.warfox.agent

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Private task checkpoints and a compact local activity history. */
class TaskMemory(context: Context) {
    private val prefs = context.getSharedPreferences("warfox_task_memory", Context.MODE_PRIVATE)

    @Synchronized
    fun save(taskId: String, prompt: String, status: String, result: String = "") {
        prefs.edit()
            .putString("task_id", taskId)
            .putString("prompt", prompt)
            .putString("status", status)
            .putString("result", result)
            .putLong("updated_at", System.currentTimeMillis())
            .apply()
        appendHistory("task", prompt, status, taskId)
    }

    @Synchronized
    fun saveConversation(prompt: String, answer: String) {
        appendHistory("user", prompt, "sent_to_ai", "")
        appendHistory("assistant", answer, "answered", "")
        prefs.edit().putString("last_ai_reply", answer).putLong("updated_at", System.currentTimeMillis()).apply()
    }

    @Synchronized
    fun saveDraft(prompt: String) {
        prefs.edit()
            .putString("prompt", prompt)
            .putString("status", "draft")
            .putLong("updated_at", System.currentTimeMillis())
            .apply()
        appendHistory("user", prompt, "draft", "")
    }

    private fun appendHistory(role: String, message: String, status: String, taskId: String) {
        val old = try { JSONArray(prefs.getString("history", "[]") ?: "[]") } catch (_: Exception) { JSONArray() }
        val next = JSONArray()
        val start = (old.length() - 29).coerceAtLeast(0)
        for (i in start until old.length()) next.put(old.optJSONObject(i))
        next.put(JSONObject().apply {
            put("role", role)
            put("message", message.take(3000))
            put("status", status)
            put("task_id", taskId)
            put("time", System.currentTimeMillis())
        })
        prefs.edit().putString("history", next.toString()).apply()
    }

    fun latest(): JSONObject = JSONObject().apply {
        put("task_id", prefs.getString("task_id", "") ?: "")
        put("prompt", prefs.getString("prompt", "") ?: "")
        put("status", prefs.getString("status", "") ?: "")
        put("result", prefs.getString("result", "") ?: "")
        put("updated_at", prefs.getLong("updated_at", 0L))
    }

    fun historyText(): String {
        val history = try { JSONArray(prefs.getString("history", "[]") ?: "[]") } catch (_: Exception) { JSONArray() }
        if (history.length() == 0) return "لا يوجد سجل محادثة محفوظ بعد."
        val output = StringBuilder()
        for (i in 0 until history.length()) {
            val item = history.optJSONObject(i) ?: continue
            output.append(if (item.optString("role") == "user") "أنت: " else "WARFOX: ")
                .append(item.optString("message")).append('\n')
                .append("الحالة: ").append(item.optString("status")).append('\n')
            if (item.optString("task_id").isNotBlank()) output.append("المهمة: ").append(item.optString("task_id")).append('\n')
            output.append('\n')
        }
        return output.toString().takeLast(14000)
    }
}
