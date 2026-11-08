package com.warfox.agent

import android.accessibilityservice.AccessibilityService
import android.graphics.Rect
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

object AgentRuntime {
    @Volatile var stopped: Boolean = true
    @Volatile var accessibilityService: WarfoxAccessibilityService? = null

    fun stop() {
        stopped = true
        accessibilityService?.disableSelf()
        accessibilityService = null
    }
}

class WarfoxAccessibilityService : AccessibilityService() {
    override fun onServiceConnected() {
        super.onServiceConnected()
        AgentRuntime.accessibilityService = this
        AgentRuntime.stopped = false
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Events are intentionally not uploaded or recorded in this foundation build.
        if (AgentRuntime.stopped) disableSelf()
    }

    override fun onInterrupt() { AgentRuntime.stop() }

    /**
     * Reads visible accessibility labels only. It does not tap, type, or transmit data.
     */
    fun describeCurrentScreen(): String {
        if (AgentRuntime.stopped) return "خدمة الوصول متوقفة."
        val root = rootInActiveWindow ?: return "لا توجد نافذة نشطة قابلة للقراءة."
        val output = StringBuilder()
        output.append("التطبيق: ").append(root.packageName ?: "غير معروف").append('\n')
        var count = 0

        fun visit(node: AccessibilityNodeInfo, depth: Int) {
            if (count >= 100 || depth > 12) return
            count++
            val label = listOfNotNull(
                node.text?.toString()?.takeIf { it.isNotBlank() },
                node.contentDescription?.toString()?.takeIf { it.isNotBlank() }
            ).distinct().joinToString(" | ")
            if (label.isNotBlank() || node.isClickable || node.isEditable) {
                val bounds = Rect()
                node.getBoundsInScreen(bounds)
                output.append("• ")
                    .append(node.className?.toString()?.substringAfterLast('.') ?: "عنصر")
                if (label.isNotBlank()) output.append(": ").append(label.take(180))
                if (node.isClickable) output.append(" [قابل للنقر]")
                if (node.isEditable) output.append(" [حقل كتابة]")
                if (!bounds.isEmpty) output.append(" [").append(bounds.left).append(',')
                    .append(bounds.top).append(" - ").append(bounds.right).append(',')
                    .append(bounds.bottom).append(']')
                output.append('\n')
            }
            for (index in 0 until node.childCount) {
                val child = node.getChild(index) ?: continue
                visit(child, depth + 1)
            }
        }

        visit(root, 0)
        if (count == 0) return "لم أجد عناصر قابلة للقراءة في هذه الشاشة."
        return output.toString().take(12000)
    }

    fun tapNode(node: AccessibilityNodeInfo): Boolean {
        if (AgentRuntime.stopped || !node.isVisibleToUser || !node.isEnabled) return false
        return node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
    }

    fun typeText(node: AccessibilityNodeInfo, value: String): Boolean {
        if (AgentRuntime.stopped || !node.isEditable || value.length > 4000) return false
        return node.performAction(
            AccessibilityNodeInfo.ACTION_SET_TEXT,
            android.os.Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, value)
            }
        )
    }

    override fun onDestroy() {
        if (AgentRuntime.accessibilityService === this) AgentRuntime.accessibilityService = null
        super.onDestroy()
    }
}
