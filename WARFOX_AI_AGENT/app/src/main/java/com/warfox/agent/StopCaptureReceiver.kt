package com.warfox.agent

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class StopCaptureReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        AgentRuntime.stop()
        context.stopService(Intent(context, ScreenCaptureService::class.java))
        context.stopService(Intent(context, StopOverlayService::class.java))
        context.stopService(Intent(context, AgentStatusService::class.java))
    }
}
