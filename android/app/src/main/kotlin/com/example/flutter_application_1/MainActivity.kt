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
        val retriever = MediaMetadataRetriever()
        val uri = Uri.parse(filePath)
        retriever.setDataSource(this, uri)
        val metadata = mutableMapOf<String, String?>()

        val keyMap = mapOf(
            "album" to MediaMetadataRetriever.METADATA_KEY_ALBUM,
            "artist" to MediaMetadataRetriever.METADATA_KEY_ARTIST,
            "album_artist" to MediaMetadataRetriever.METADATA_KEY_ALBUMARTIST,
            "author" to MediaMetadataRetriever.METADATA_KEY_AUTHOR,
            "composer" to MediaMetadataRetriever.METADATA_KEY_COMPOSER,
            "date" to MediaMetadataRetriever.METADATA_KEY_DATE,
            "genre" to MediaMetadataRetriever.METADATA_KEY_GENRE,
            "title" to MediaMetadataRetriever.METADATA_KEY_TITLE,
            "year" to MediaMetadataRetriever.METADATA_KEY_YEAR,
            "duration" to MediaMetadataRetriever.METADATA_KEY_DURATION,
            "track_number" to MediaMetadataRetriever.METADATA_KEY_CD_TRACK_NUMBER,
            "bitrate" to MediaMetadataRetriever.METADATA_KEY_BITRATE
        )

        for ((key, value) in keyMap) {
            metadata[key] = retriever.extractMetadata(value)
        }

        val art = retriever.embeddedPicture
        if (art != null) {
            metadata["album_art"] = Base64.encodeToString(art, Base64.NO_WRAP)
        }

        retriever.release()
        return metadata
    }
}
