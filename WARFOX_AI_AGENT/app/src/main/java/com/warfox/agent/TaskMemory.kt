package com.warfox.agent

import android.content.Context
import org.json.JSONObject

/**
 * Small private on-device checkpoint for the latest task.
 * Stored in app-private SharedPreferences; never synced by this class.
 */
class TaskMemory(context: Context) {
    private val prefs = context.getSharedPreferences("warfox_task_memory", Context.MODE_PRIVATE)

    fun save(taskId: String, prompt: String, status: String, result: String = "") {
        prefs.edit()
            .putString("task_id", taskId)
            .putString("prompt", prompt)
            .putString("status", status)
            .putString("result", result)
            .putLong("updated_at", System.currentTimeMillis())
            .apply()
    }

    fun saveDraft(prompt: String) {
        prefs.edit()
            .putString("prompt", prompt)
            .putString("status", "draft")
            .putLong("updated_at", System.currentTimeMillis())
            .apply()
    }

    fun latest(): JSONObject {
        return JSONObject().apply {
            put("task_id", prefs.getString("task_id", "") ?: "")
            put("prompt", prefs.getString("prompt", "") ?: "")
            put("status", prefs.getString("status", "") ?: "")
            put("result", prefs.getString("result", "") ?: "")
            put("updated_at", prefs.getLong("updated_at", 0L))
        }
    }
}
