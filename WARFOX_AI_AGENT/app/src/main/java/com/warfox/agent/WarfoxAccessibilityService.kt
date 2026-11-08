package com.warfox.agent

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class WarfoxAccessibilityService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Events are intentionally not uploaded or recorded in this foundation build.
    }

    override fun onInterrupt() {}

    fun tapNode(node: AccessibilityNodeInfo): Boolean {
        if (!node.isVisibleToUser || !node.isEnabled) return false
        return node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
    }

    fun typeText(node: AccessibilityNodeInfo, value: String): Boolean {
        if (!node.isEditable || value.length > 4000) return false
        return node.performAction(
            AccessibilityNodeInfo.ACTION_SET_TEXT,
            android.os.Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, value)
            }
        )
    }
}
