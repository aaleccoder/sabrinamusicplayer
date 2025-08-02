package com.example.flutter_application_1

import android.content.ContentUris
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import android.util.LruCache
import android.util.Size
import androidx.annotation.NonNull
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.security.MessageDigest

class MainActivity : AudioServiceFragmentActivity() {
    private val CHANNEL = "com.example.flutter_application_1/metadata"

    // Use coroutines for better concurrency management
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    // Cache directory for album art thumbnails
    private val albumArtCacheDir by lazy {
        File(cacheDir, "album_art_cache").apply {
            if (!exists()) mkdirs()
        }
    }

    // In-memory LRU cache for hot albums (256MB cache)
    private val memoryCache = LruCache<String, Bitmap>(256 * 2048 * 2048) // 256MB

    // Cache for album art URIs by album ID to avoid duplicate processing
    private val albumArtCache = mutableMapOf<Long, String?>()
    
    // Single retriever instance per thread for better resource management
    private val retrieverThreadLocal = ThreadLocal.withInitial { MediaMetadataRetriever() }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAllMusicFiles" -> {
                    // Use coroutines for better concurrency management
                    scope.launch {
                        try {
                            val musicFiles = getAllMusicFiles()
                            // Switch back to the main thread to send the result
                            withContext(Dispatchers.Main) {
                                result.success(musicFiles)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error(
                                    "MEDIA_STORE_ERROR",
                                    "Error fetching music from MediaStore.",
                                    e.toString()
                                )
                            }
                        }
                    }
                }
                "extractFullSizeAlbumArt" -> {
                    val trackIdString = call.argument<String>("trackId")
                    if (trackIdString != null) {
                        scope.launch {
                            try {
                                val trackId = trackIdString.toLong()
                                val fullSizeAlbumArtUri = extractFullSizeAlbumArt(trackId)
                                withContext(Dispatchers.Main) {
                                    result.success(fullSizeAlbumArtUri)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error(
                                        "ALBUM_ART_ERROR",
                                        "Error extracting full-size album art.",
                                        e.toString()
                                    )
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "trackId is required", null)
                    }
                }
                 "getPathFromUri" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        scope.launch {
                            try {
                                val path = getPathFromUri(uriString)
                                withContext(Dispatchers.Main) {
                                    result.success(path)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error(
                                        "URI_ERROR",
                                        "Error resolving URI to path.",
                                        e.toString()
                                    )
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "uri is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private suspend fun getAllMusicFiles(): List<Map<String, String?>> {
        val list = mutableListOf<Map<String, String?>>()

        // First, populate album art cache by querying albums
        populateAlbumArtCache()

        // For genres, build a map for older Android versions
        val audioIdToGenreMap = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            getAudioIdToGenreMap()
        } else {
            emptyMap()
        }

        // Then query tracks with projection based on API level
        val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.ALBUM_ID,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.YEAR,
                MediaStore.Audio.Media.TRACK,
                MediaStore.Audio.Media.GENRE // Added in API 30
            )
        } else {
            arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.ALBUM_ID,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.YEAR,
                MediaStore.Audio.Media.TRACK
            )
        }
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

        contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection, selection, null,
            "${MediaStore.Audio.Media.TITLE} ASC"
        )?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val albumIdCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val durCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val yearCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.YEAR)
            val trackCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)
            val genreCol = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.GENRE)
            } else {
                -1
            }

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idCol)
                val albumId = cursor.getLong(albumIdCol)

                val genre = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    cursor.getString(genreCol)
                } else {
                    audioIdToGenreMap[id]
                }

                // Create content URI for this track (modern Android approach)
                val contentUri = ContentUris.withAppendedId(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    id
                ).toString()

                // Get album art URI from cache (already processed)
                val albumArtUri = albumArtCache[albumId]

                list += mapOf(
                    "id" to id.toString(),
                    "title" to cursor.getString(titleCol),
                    "artist" to cursor.getString(artistCol),
                    "album" to cursor.getString(albumCol),
                    "album_art_uri" to albumArtUri,
                    "duration" to cursor.getString(durCol),
                    "year" to cursor.getString(yearCol),
                    "track" to cursor.getInt(trackCol).takeIf { it > 0 }?.toString(),
                    "path" to contentUri,  // Content URI instead of file path
                    "genre" to genre
                )
            }
        }
        return list
    }
    
    /**
     * Populates the album art cache by processing each unique album only once
     */
    private suspend fun populateAlbumArtCache() {
        val albumProjection = arrayOf(
            MediaStore.Audio.Albums._ID,
            MediaStore.Audio.Albums.ALBUM_ART
        )
        
        contentResolver.query(
            MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
            albumProjection, null, null,
            "${MediaStore.Audio.Albums.ALBUM} ASC"
        )?.use { cursor ->
            val albumIdCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums._ID)
            val albumArtCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums.ALBUM_ART)
            
            while (cursor.moveToNext()) {
                val albumId = cursor.getLong(albumIdCol)
                val systemAlbumArt = cursor.getString(albumArtCol)
                
                // Skip if we already processed this album
                if (albumArtCache.containsKey(albumId)) continue
                
                // Try to get cached album art or extract new one
                val albumArtUri = getOrExtractAlbumArt(albumId, systemAlbumArt)
                albumArtCache[albumId] = albumArtUri
            }
        }
    }

    /**
     * Gets album art from cache or extracts it for the given album
     * @param albumId The album ID to build the cache filename
     * @param systemAlbumArt System-provided album art path (may be null)
     * @return Album art URI or null if not available
     */
    private suspend fun getOrExtractAlbumArt(albumId: Long, systemAlbumArt: String?): String? {
        // Create cache filename based on album ID
        val cacheFileName = "album_${albumId}.jpg"
        val cacheFile = File(albumArtCacheDir, cacheFileName)
        
        // Return cached version if it exists
        if (cacheFile.exists()) {
            return Uri.fromFile(cacheFile).toString()
        }
        
        // Check memory cache first
        val cacheKey = "album_$albumId"
        memoryCache.get(cacheKey)?.let { bitmap ->
            // Save to disk cache if not already there
            if (saveBitmapToCache(bitmap, cacheFile)) {
                return Uri.fromFile(cacheFile).toString()
            }
        }
        
        // Try Android Q+ ContentResolver.loadThumbnail first
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val albumUri = ContentUris.withAppendedId(
                    MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                    albumId
                )
                val thumbnail = contentResolver.loadThumbnail(albumUri, Size(2048, 2048), null)
                
                if (saveBitmapToCache(thumbnail, cacheFile)) {
                    // Cache in memory for hot access
                    memoryCache.put(cacheKey, thumbnail)
                    return Uri.fromFile(cacheFile).toString()
                }
            } catch (e: Exception) {
                Log.d("MainActivity", "ContentResolver.loadThumbnail failed for album $albumId, falling back to MediaMetadataRetriever", e)
            }
        }
        
        // Fallback to MediaMetadataRetriever for older versions or when loadThumbnail fails
        return extractAlbumArtWithRetriever(albumId, cacheFile, cacheKey)
    }
    
    /**
     * Fallback method using MediaMetadataRetriever for album art extraction
     */
    private suspend fun extractAlbumArtWithRetriever(albumId: Long, cacheFile: File, cacheKey: String): String? {
        val retriever = retrieverThreadLocal.get()
        
        try {
            // Find a track from this album to extract art from
            val trackId = getTrackIdFromAlbum(albumId) ?: return getDefaultAlbumArt()
            
            val trackUri = ContentUris.withAppendedId(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                trackId
            )
            
            retriever.setDataSource(this, trackUri)
            val albumArt = retriever.embeddedPicture
            
            if (albumArt != null) {
                // Decode the byte array to bitmap
                val originalBitmap = BitmapFactory.decodeByteArray(albumArt, 0, albumArt.size)
                
                if (originalBitmap != null) {
                    // Compress to 2048x2048 thumbnail
                    val thumbnail = compressBitmapToThumbnail(originalBitmap, 2048, 2048)
                    
                    // Save to cache
                    if (saveBitmapToCache(thumbnail, cacheFile)) {
                        // Cache in memory for hot access
                        memoryCache.put(cacheKey, thumbnail)
                        // Don't recycle thumbnail as it's now in memory cache
                        originalBitmap.recycle()
                        return Uri.fromFile(cacheFile).toString()
                    }
                    
                    originalBitmap.recycle()
                    thumbnail.recycle()
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error extracting album art for album $albumId", e)
        }
        
        return getDefaultAlbumArt()
    }
    
    /**
     * Gets a track ID from the specified album for art extraction
     */
    private fun getTrackIdFromAlbum(albumId: Long): Long? {
        val projection = arrayOf(MediaStore.Audio.Media._ID)
        val selection = "${MediaStore.Audio.Media.ALBUM_ID} = ? AND ${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val selectionArgs = arrayOf(albumId.toString())
        
        contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection, selection, selectionArgs, null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
            }
        }
        return null
    }

    /**
     * Builds a map from audio ID to genre name for devices older than Android 11 (API 30)
     */
    private fun getAudioIdToGenreMap(): Map<Long, String> {
        val audioIdToGenreMap = mutableMapOf<Long, String>()
        val genresProjection = arrayOf(
            MediaStore.Audio.Genres._ID,
            MediaStore.Audio.Genres.NAME
        )

        contentResolver.query(
            MediaStore.Audio.Genres.EXTERNAL_CONTENT_URI,
            genresProjection,
            null,
            null,
            null
        )?.use { genresCursor ->
            val genreIdCol = genresCursor.getColumnIndexOrThrow(MediaStore.Audio.Genres._ID)
            val genreNameCol = genresCursor.getColumnIndexOrThrow(MediaStore.Audio.Genres.NAME)

            while (genresCursor.moveToNext()) {
                val genreId = genresCursor.getLong(genreIdCol)
                val genreName = genresCursor.getString(genreNameCol)

                val membersUri = MediaStore.Audio.Genres.Members.getContentUri("external", genreId)
                contentResolver.query(membersUri, arrayOf(MediaStore.Audio.Media._ID), "${MediaStore.Audio.Media.IS_MUSIC} != 0", null, null)?.use { membersCursor ->
                    val audioIdCol = membersCursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                    while (membersCursor.moveToNext()) {
                        val audioId = membersCursor.getLong(audioIdCol)
                        audioIdToGenreMap[audioId] = genreName
                    }
                }
            }
        }
        return audioIdToGenreMap
    }
    
    /**
     * Returns a default album art URI for graceful fallback
     */
    private fun getDefaultAlbumArt(): String? {
        // You can return a default image URI from assets here
        // For now, return null to maintain current behavior
        return null
    }
    
    /**
     * Compresses a bitmap to the specified dimensions
     * @param original The original bitmap
     * @param width Target width
     * @param height Target height
     * @return Compressed bitmap
     */
    private fun compressBitmapToThumbnail(original: Bitmap, width: Int, height: Int): Bitmap {
        return Bitmap.createScaledBitmap(original, width, height, true)
    }
    
    /**
     * Saves a bitmap to the cache directory using Kotlin's use idiom
     * @param bitmap The bitmap to save
     * @param file The target file
     * @return True if saved successfully, false otherwise
     */
    private fun saveBitmapToCache(bitmap: Bitmap, file: File): Boolean {
        return try {
            FileOutputStream(file).use { outputStream ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 85, outputStream)
                outputStream.flush()
            }
            true
        } catch (e: IOException) {
            Log.e("MainActivity", "Error saving bitmap to cache", e)
            false
        }
    }
    
    /**
     * Extracts full-size album art using album-based caching
     * @param trackId The track ID to get album information
     * @return Full-size album art URI or null if not available
     */
    private suspend fun extractFullSizeAlbumArt(trackId: Long): String? {
        // First get the album ID for this track
        val albumId = getAlbumIdFromTrack(trackId) ?: return getDefaultAlbumArt()
        
        // Create cache filename for full-size image based on album ID
        val cacheFileName = "album_full_${albumId}.jpg"
        val cacheFile = File(albumArtCacheDir, cacheFileName)
        
        // Return cached version if it exists
        if (cacheFile.exists()) {
            return Uri.fromFile(cacheFile).toString()
        }
        
        val retriever = retrieverThreadLocal.get()
        
        try {
            val trackUri = ContentUris.withAppendedId(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                trackId
            )
            
            retriever.setDataSource(this, trackUri)
            val albumArt = retriever.embeddedPicture
            
            if (albumArt != null) {
                // Decode the byte array to bitmap (keep original size)
                val originalBitmap = BitmapFactory.decodeByteArray(albumArt, 0, albumArt.size)
                
                if (originalBitmap != null) {
                    // Save full-size image to cache
                    if (saveBitmapToCache(originalBitmap, cacheFile)) {
                        originalBitmap.recycle()
                        return Uri.fromFile(cacheFile).toString()
                    }
                    
                    originalBitmap.recycle()
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error extracting full-size album art for track $trackId", e)
        }
        
        return getDefaultAlbumArt()
    }
    
    /**
     * Gets the album ID for a given track ID
     */
    private fun getAlbumIdFromTrack(trackId: Long): Long? {
        val projection = arrayOf(MediaStore.Audio.Media.ALBUM_ID)
        val selection = "${MediaStore.Audio.Media._ID} = ?"
        val selectionArgs = arrayOf(trackId.toString())
        
        contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection, selection, selectionArgs, null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID))
            }
        }
        return null
    }

    private fun getPathFromUri(uriString: String): String? {
        val uri = Uri.parse(uriString)
        val projection = arrayOf(MediaStore.Audio.Media.DATA)
        
        contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val dataIndex = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
                return cursor.getString(dataIndex)
            }
        }
        return null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // Cancel all coroutines and clean up resources
        scope.cancel()
        
        // Clean up memory cache
        memoryCache.evictAll()
        
        // Clean up thread-local retriever instances
        try {
            retrieverThreadLocal.get()?.release()
            retrieverThreadLocal.remove()
        } catch (e: Exception) {
            Log.e("MainActivity", "Error releasing MediaMetadataRetriever in onDestroy", e)
        }
    }
}
