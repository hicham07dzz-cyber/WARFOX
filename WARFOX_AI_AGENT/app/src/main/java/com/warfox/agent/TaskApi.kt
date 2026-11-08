package com.warfox.agent

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/**
 * Minimal adapter for the existing Termux bridge.
 * Only loopback HTTP is allowed by the app's network security configuration.
 */
class TaskApi(private val baseUrl: String = "http://127.0.0.1:8765") {
    private fun post(path: String, body: JSONObject): JSONObject {
        val connection = (URL(baseUrl.trimEnd('/') + path).openConnection() as HttpURLConnection)
        connection.requestMethod = "POST"
        connection.connectTimeout = 8000
        connection.readTimeout = 15000
        connection.doOutput = true
        connection.setRequestProperty("Content-Type", "application/json; charset=utf-8")
        try {
            connection.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
            val stream = if (connection.responseCode in 200..299) connection.inputStream else connection.errorStream
            val text = stream?.bufferedReader()?.use { it.readText() }.orEmpty()
            return JSONObject(text.ifBlank { "{}" })
        } finally {
            connection.disconnect()
        }
    }

    fun createTask(prompt: String): JSONObject =
        post("/api/chat/create", JSONObject().put("message", prompt))

    fun startWorker(taskId: String): JSONObject =
        post("/api/worker/run", JSONObject().put("task_id", taskId))

    fun getTask(taskId: String): JSONObject {
        val connection = URL(baseUrl.trimEnd('/') + "/api/chat/task?id=$taskId")
            .openConnection() as HttpURLConnection
        connection.requestMethod = "GET"
        connection.connectTimeout = 8000
        connection.readTimeout = 10000
        return try {
            val stream = if (connection.responseCode in 200..299) connection.inputStream else connection.errorStream
            JSONObject(stream?.bufferedReader()?.use { it.readText() }.orEmpty().ifBlank { "{}" })
        } finally {
            connection.disconnect()
        }
    }
}
