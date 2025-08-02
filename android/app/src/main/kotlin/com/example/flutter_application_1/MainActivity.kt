package com.example.flutter_application_1

import androidx.annotation.NonNull
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.flutter_application_1/metadata"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getMetadata") {
                val filePath = call.argument<String>("filePath")
                if (filePath == null) {
                    result.error("INVALID_ARGUMENT", "File path is null.", null)
                } else {
                    try {
                        val metadata = getMetadata(filePath)
                        result.success(metadata)
                    } catch (e: Exception) {
                        result.error("METADATA_ERROR", "Error extracting metadata.", e.toString())
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getMetadata(filePath: String): Map<String, String?> {
        var retriever: MediaMetadataRetriever? = null
        try {
            retriever = MediaMetadataRetriever()
            
            // Use file path directly instead of URI for better performance
            retriever.setDataSource(filePath)
            
            val metadata = mutableMapOf<String, String?>()

            // Optimized key mapping - only extract essential metadata first
            val essentialKeyMap = mapOf(
                "title" to MediaMetadataRetriever.METADATA_KEY_TITLE,
                "artist" to MediaMetadataRetriever.METADATA_KEY_ARTIST,
                "album" to MediaMetadataRetriever.METADATA_KEY_ALBUM,
                "genre" to MediaMetadataRetriever.METADATA_KEY_GENRE,
                "year" to MediaMetadataRetriever.METADATA_KEY_YEAR,
                "track_number" to MediaMetadataRetriever.METADATA_KEY_CD_TRACK_NUMBER,
                "duration" to MediaMetadataRetriever.METADATA_KEY_DURATION
            )

            // Extract essential metadata
            for ((key, value) in essentialKeyMap) {
                metadata[key] = retriever.extractMetadata(value)
            }

            // Extract album art with optimizations
            val art = retriever.embeddedPicture
            if (art != null && art.isNotEmpty()) {
                try {
                    // Only process reasonable sized album art (< 2MB)
                    if (art.size <= 2_000_000) {
                        metadata["album_art"] = Base64.encodeToString(art, Base64.NO_WRAP)
                    } else {
                        // Skip oversized album art to avoid performance issues
                        android.util.Log.w("MetadataService", "Skipping oversized album art (${art.size} bytes) for: $filePath")
                    }
                } catch (e: Exception) {
                    android.util.Log.e("MetadataService", "Error encoding album art for: $filePath", e)
                }
            }

            return metadata
            
        } catch (e: Exception) {
            android.util.Log.e("MetadataService", "Error extracting metadata from: $filePath", e)
            return emptyMap()
        } finally {
            try {
                retriever?.release()
            } catch (e: Exception) {
                android.util.Log.e("MetadataService", "Error releasing metadata retriever", e)
            }
        }
    }
}
