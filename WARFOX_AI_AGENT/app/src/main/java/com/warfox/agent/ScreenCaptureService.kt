package com.warfox.agent

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import java.io.File
import java.io.FileOutputStream

/**
 * Captures one user-approved screen frame and stores it privately on-device.
 * No screenshot is uploaded or shared with a server.
 */
class ScreenCaptureService : Service() {
    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var workerThread: HandlerThread? = null
    private var workerHandler: Handler? = null
    private var captured = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createChannel()
        startForeground(41, notification())

        val resultCode = intent?.getIntExtra("resultCode", 0) ?: 0
        val data = if (Build.VERSION.SDK_INT >= 33) {
            intent?.getParcelableExtra("captureData", Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent?.getParcelableExtra<Intent>("captureData")
        }
        if (resultCode == 0 || data == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        try {
            val manager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            projection = manager.getMediaProjection(resultCode, data)
            startOneFrameCapture()
        } catch (error: Exception) {
            sendFailure(error.message ?: "تعذر بدء التقاط الشاشة")
            stopSelf()
        }
        return START_NOT_STICKY
    }

    private fun startOneFrameCapture() {
        val metrics = resources.displayMetrics
        val width = metrics.widthPixels.coerceAtLeast(1)
        val height = metrics.heightPixels.coerceAtLeast(1)
        val density = metrics.densityDpi

        workerThread = HandlerThread("WarfoxScreenCapture").also { it.start() }
        workerHandler = Handler(workerThread!!.looper)
        projection?.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() { stopSelf() }
        }, workerHandler)
        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)

        imageReader!!.setOnImageAvailableListener({ reader ->
            if (captured) return@setOnImageAvailableListener
            val image = reader.acquireLatestImage() ?: return@setOnImageAvailableListener
            try {
                val plane = image.planes[0]
                val buffer = plane.buffer
                val pixelStride = plane.pixelStride
                val rowStride = plane.rowStride
                val rowPadding = rowStride - pixelStride * width
                val paddedBitmap = Bitmap.createBitmap(
                    width + rowPadding / pixelStride, height, Bitmap.Config.ARGB_8888
                )
                paddedBitmap.copyPixelsFromBuffer(buffer)
                val bitmap = Bitmap.createBitmap(paddedBitmap, 0, 0, width, height)
                paddedBitmap.recycle()

                val output = File(filesDir, "latest_screen.jpg")
                FileOutputStream(output).use { stream ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 82, stream)
                }
                bitmap.recycle()
                captured = true

                sendBroadcast(Intent(ACTION_FRAME_CAPTURED).setPackage(packageName).apply {
                    putExtra(EXTRA_FILE_PATH, output.absolutePath)
                    putExtra(EXTRA_WIDTH, width)
                    putExtra(EXTRA_HEIGHT, height)
                })
                stopSelf()
            } catch (error: Exception) {
                sendFailure(error.message ?: "فشل حفظ صورة الشاشة")
                stopSelf()
            } finally {
                image.close()
            }
        }, workerHandler)

        virtualDisplay = projection?.createVirtualDisplay(
            "WARFOX_SCREEN_ONCE",
            width,
            height,
            density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader!!.surface,
            null,
            workerHandler
        )
        if (virtualDisplay == null) {
            sendFailure("تعذر إنشاء شاشة الالتقاط")
            stopSelf()
        }
    }

    private fun sendFailure(message: String) {
        sendBroadcast(Intent(ACTION_CAPTURE_FAILED).setPackage(packageName).apply {
            putExtra(EXTRA_ERROR, message)
        })
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            val channel = NotificationChannel(
                "warfox_capture", "WARFOX screen capture", NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun notification(): Notification {
        val stopIntent = Intent(this, StopCaptureReceiver::class.java)
        val pending = PendingIntent.getBroadcast(
            this, 42, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, "warfox_capture")
            else Notification.Builder(this)
        return builder
            .setContentTitle("WARFOX AI AGENT")
            .setContentText("التقاط صورة واحدة بموافقتك — محلياً على الهاتف")
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .addAction(android.R.drawable.ic_media_pause, "إيقاف", pending)
            .build()
    }

    override fun onDestroy() {
        virtualDisplay?.release()
        virtualDisplay = null
        imageReader?.setOnImageAvailableListener(null, null)
        imageReader?.close()
        imageReader = null
        projection?.stop()
        projection = null
        workerThread?.quitSafely()
        workerThread = null
        workerHandler = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val ACTION_FRAME_CAPTURED = "com.warfox.agent.FRAME_CAPTURED"
        const val ACTION_CAPTURE_FAILED = "com.warfox.agent.CAPTURE_FAILED"
        const val EXTRA_FILE_PATH = "filePath"
        const val EXTRA_WIDTH = "width"
        const val EXTRA_HEIGHT = "height"
        const val EXTRA_ERROR = "error"
    }
}
