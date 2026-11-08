package com.warfox.agent
import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.nio.ByteBuffer
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

object AiProviderStore {
    private const val PREFS = "warfox_ai_provider"
    private const val KEY_ALIAS = "warfox_ai_provider_key_v1"
    private const val API_KEY = "api_key_enc"
    private const val ENDPOINT = "endpoint"
    private const val MODEL = "model"
    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private fun secretKey(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setRandomizedEncryptionRequired(true).build())
        return generator.generateKey()
    }
    private fun encrypt(value: String): String {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey())
        val encrypted = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        val packed = ByteBuffer.allocate(4 + cipher.iv.size + encrypted.size).putInt(cipher.iv.size).put(cipher.iv).put(encrypted).array()
        return Base64.encodeToString(packed, Base64.NO_WRAP)
    }
    private fun decrypt(value: String): String {
        val packed = ByteBuffer.wrap(Base64.decode(value, Base64.NO_WRAP))
        val ivSize = packed.int
        require(ivSize in 12..16) { "Invalid encrypted API key" }
        val iv = ByteArray(ivSize).also { packed.get(it) }
        val encrypted = ByteArray(packed.remaining()).also { packed.get(it) }
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(128, iv))
        return String(cipher.doFinal(encrypted), Charsets.UTF_8)
    }
    fun save(context: Context, endpoint: String, model: String, apiKey: String) {
        require(endpoint.trim().startsWith("https://", true)) { "يجب استخدام رابط HTTPS لحماية المفتاح." }
        require(model.isNotBlank()) { "أدخل اسم النموذج." }
        require(apiKey.isNotBlank()) { "أدخل مفتاح API." }
        prefs(context).edit().putString(ENDPOINT, endpoint.trim().trimEnd('/')).putString(MODEL, model.trim())
            .putString(API_KEY, encrypt(apiKey.trim())).apply()
    }
    fun endpoint(context: Context) = prefs(context).getString(ENDPOINT, "https://api.openai.com/v1") ?: ""
    fun model(context: Context) = prefs(context).getString(MODEL, "") ?: ""
    fun apiKey(context: Context): String = prefs(context).getString(API_KEY, null)?.let { decrypt(it) } ?: ""
    fun isConfigured(context: Context): Boolean = try { endpoint(context).startsWith("https://") && model(context).isNotBlank() && apiKey(context).isNotBlank() } catch (_: Exception) { false }
    fun clear(context: Context) {
        prefs(context).edit().clear().apply()
        try { KeyStore.getInstance("AndroidKeyStore").apply { load(null); deleteEntry(KEY_ALIAS) } } catch (_: Exception) { }
    }
}
