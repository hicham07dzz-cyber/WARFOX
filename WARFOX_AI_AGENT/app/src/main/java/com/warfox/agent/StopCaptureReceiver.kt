package com.warfox.agent

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class StopCaptureReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        context.stopService(Intent(context, ScreenCaptureService::class.java))
    }
}
