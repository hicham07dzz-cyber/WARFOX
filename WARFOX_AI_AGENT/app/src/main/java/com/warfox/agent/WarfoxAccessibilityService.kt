package com.warfox.agent

import android.accessibilityservice.AccessibilityService
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
