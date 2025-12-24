import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart';

class LyricsService {
  static const String _baseUrl = 'https://api.genius.com';
  static const String _geniusUrl = 'https://genius.com';
  static const String _lrcLibApiUrl = 'https://lrclib.net/api';

  Future<String?> fetchLyrics(
    String title,
    String artist, {
    String? album,
    int? durationSeconds,
  }) async {
    final lrcLibLyrics = await _fetchFromLrcLib(
      title: title,
      artist: artist,
      album: album,
      durationSeconds: durationSeconds,
    );

    print('LRCLIB lyrics: $lrcLibLyrics');

    if (lrcLibLyrics != null && lrcLibLyrics.isNotEmpty) {
      return lrcLibLyrics;
    }

    return _fetchFromGenius(title, artist);
  }

  Future<String?> _fetchFromLrcLib({
    required String title,
    required String artist,
    String? album,
    int? durationSeconds,
  }) async {
    try {
      final queryParameters = <String, String>{
        'track_name': title,
        'artist_name': artist,
        if (album != null && album.isNotEmpty) 'album_name': album,
        if (durationSeconds != null && durationSeconds > 0)
          'duration': durationSeconds.toString(),
      };

      final uri = Uri.parse(
        '$_lrcLibApiUrl/get',
      ).replace(queryParameters: queryParameters);

      final response = await http.get(uri);

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        log('LRCLIB request failed: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final lyrics = (data['syncedLyrics'] ?? data['plainLyrics']) as String?;

      if (lyrics != null && lyrics.trim().isNotEmpty) {
        return lyrics.trim();
      }
    } catch (e) {
      log('Error fetching lyrics from LRCLIB: $e');
    }

    return null;
  }

  Future<String?> _fetchFromGenius(String title, String artist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('geniusApiKey');

      if (token == null || token.isEmpty) {
        log('Genius API key not found.');
        return null;
      }

      final uri = Uri.parse(
        '$_baseUrl/search',
      ).replace(queryParameters: {'q': '$title $artist'});

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final hits = json['response']['hits'] as List;
        if (hits.isNotEmpty) {
          final path = hits[0]['result']['path'];
          log('Found song path: $path');
          return await _scrapeLyrics(path);
        } else {
          log('No hits found for $title by $artist');
        }
      } else {
        log('Failed to search for song: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching lyrics from Genius: $e');
    }

    return null;
  }

  Future<String?> _scrapeLyrics(String path) async {
    try {
      // Add headers to mimic a real browser request
      final response = await http.get(
        Uri.parse('$_geniusUrl$path'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        },
      );

      if (response.statusCode == 200) {
        log(
          'Successfully fetched page, response length: ${response.body.length}',
        );

        // First, try to extract lyrics from embedded JSON data
        var lyricsFromJson = await _extractLyricsFromJson(response.body);
        if (lyricsFromJson != null && lyricsFromJson.isNotEmpty) {
          log('Successfully extracted lyrics from embedded JSON data');
          return lyricsFromJson;
        }

        // If JSON extraction fails, try HTML parsing (for pages that might have server-side rendered content)
        var document = parse(response.body);

        log('=== TRYING HTML EXTRACTION ===');

        // Check for the data-lyrics-container
        var lyricsContainer = document.querySelector(
          'div[data-lyrics-container="true"]',
        );
        log(
          'Found div[data-lyrics-container="true"]: ${lyricsContainer != null}',
        );

        if (lyricsContainer != null) {
          var result = await _extractLyricsFromContainer(lyricsContainer);
          if (result != null && result.isNotEmpty) {
            return result;
          }
        }

        // Try other potential containers
        var potentialSelectors = [
          '#lyrics-root div[class*="Lyrics__Container"]',
          'div[class*="lyrics"]',
          'div[class*="Lyrics"]',
          '.lyrics',
        ];

        for (var selector in potentialSelectors) {
          var elements = document.querySelectorAll(selector);
          for (var element in elements) {
            var paragraphs = element.querySelectorAll('p');
            if (paragraphs.isNotEmpty) {
              log(
                'Trying HTML extraction from $selector with ${paragraphs.length} paragraphs',
              );
              var result = await _extractLyricsFromContainer(element);
              if (result != null && result.isNotEmpty) {
                return result;
              }
            }
          }
        }

        log('HTML extraction failed - content is likely JavaScript-rendered');
      } else {
        log('Failed to fetch lyrics page: ${response.statusCode}');
      }
    } catch (e) {
      log('Error in _scrapeLyrics: $e');
    }

    log('All lyrics extraction methods failed');
    return null;
  }

  Future<String?> _extractLyricsFromJson(String htmlContent) async {
    try {
      log('=== TRYING JSON EXTRACTION ===');

      // Look for embedded JSON data that might contain lyrics
      // Genius often embeds initial data in script tags
      var scriptTagPatterns = [
        RegExp(r'window\.__PRELOADED_STATE__\s*=\s*({.+?});', dotAll: true),
        RegExp(r'window\.__INITIAL_DATA__\s*=\s*({.+?});', dotAll: true),
      ];

      for (var pattern in scriptTagPatterns) {
        var matches = pattern.allMatches(htmlContent);
        for (var match in matches) {
          try {
            var jsonStr = match.group(1);
            if (jsonStr != null && jsonStr.isNotEmpty) {
              log('Found potential JSON data, length: ${jsonStr.length}');

              // Try to parse the JSON
              var jsonData = jsonDecode(jsonStr);

              // Look for lyrics in various possible locations in the JSON
              var lyrics = _searchForLyricsInJson(jsonData);
              if (lyrics != null && lyrics.isNotEmpty) {
                log('Successfully found lyrics in JSON data');
                return lyrics;
              }
            }
          } catch (e) {
            log('Failed to parse JSON from script tag: $e');
            continue;
          }
        }
      }

      // Also try to find any script tag that might contain lyrics data
      var document = parse(htmlContent);
      var scriptTags = document.querySelectorAll('script');

      for (var script in scriptTags) {
        var scriptContent = script.text;
        if (scriptContent.contains('lyrics') ||
            scriptContent.contains('Lyrics')) {
          log(
            'Found script tag containing "lyrics", length: ${scriptContent.length}',
          );

          // Try to extract JSON from this script
          var jsonMatches = RegExp(
            r'{[^{}]*"lyrics"[^{}]*}',
            dotAll: true,
          ).allMatches(scriptContent);
          for (var match in jsonMatches) {
            try {
              var jsonStr = match.group(0);
              if (jsonStr != null) {
                var jsonData = jsonDecode(jsonStr);
                var lyrics = _searchForLyricsInJson(jsonData);
                if (lyrics != null && lyrics.isNotEmpty) {
                  return lyrics;
                }
              }
            } catch (e) {
              continue;
            }
          }
        }
      }

      log('No lyrics found in embedded JSON data');
      return null;
    } catch (e) {
      log('Error in _extractLyricsFromJson: $e');
      return null;
    }
  }

  String? _searchForLyricsInJson(dynamic jsonData) {
    try {
      // Recursively search through the JSON structure for lyrics
      if (jsonData is Map) {
        for (var key in jsonData.keys) {
          var keyStr = key.toString().toLowerCase();

          // Check if this key might contain lyrics
          if (keyStr.contains('lyrics') ||
              keyStr.contains('body') ||
              keyStr.contains('content')) {
            var value = jsonData[key];
            if (value is String && value.trim().isNotEmpty) {
              // Check if this looks like lyrics (contains common lyrics patterns)
              if (_looksLikeLyrics(value)) {
                log('Found lyrics in JSON key: $key');
                return _cleanLyricsText(value);
              }
            }
          }

          // Recursively search nested objects
          var nestedResult = _searchForLyricsInJson(jsonData[key]);
          if (nestedResult != null) {
            return nestedResult;
          }
        }
      } else if (jsonData is List) {
        for (var item in jsonData) {
          var result = _searchForLyricsInJson(item);
          if (result != null) {
            return result;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  bool _looksLikeLyrics(String text) {
    // Check if text looks like lyrics based on common patterns
    var lyricsPatterns = [
      RegExp(r'\[.*?\]'), // [Verse 1], [Chorus], etc.
      RegExp(r'^\s*[A-Z].*\n.*[a-z]', multiLine: true), // Capitalized lines
      RegExp(r'\n.*\n'), // Multiple lines
    ];

    for (var pattern in lyricsPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }

    // Also check length and line count
    var lines = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    return lines.length > 3 && text.length > 50;
  }

  String _cleanLyricsText(String text) {
    // Clean up the lyrics text
    // Remove HTML entities
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    // Clean up extra whitespace
    var lines = text.split('\n');
    var cleanLines = <String>[];

    for (var line in lines) {
      var cleanLine = line.trim();
      if (cleanLine.isNotEmpty) {
        cleanLines.add(cleanLine);
      }
    }

    return cleanLines.join('\n');
  }

  Future<String?> _extractLyricsFromContainer(dynamic container) async {
    try {
      // Look for the main paragraph containing lyrics
      var lyricsP = container.querySelector('p');

      if (lyricsP != null) {
        log('Found lyrics paragraph element');

        // Convert <br> tags to newlines before extracting text
        var htmlContent = lyricsP.innerHtml;
        log('Raw HTML content length: ${htmlContent.length}');

        if (htmlContent.isEmpty) {
          log('HTML content is empty, trying text content directly');
          var textContent = lyricsP.text.trim();
          if (textContent.isNotEmpty) {
            log('Found text content: ${textContent.length} characters');
            return textContent;
          }
        }

        // Replace <br> and <br/> tags with newlines
        htmlContent = htmlContent.replaceAll(
          RegExp(r'<br\s*/?>', caseSensitive: false),
          '\n',
        );

        // Parse the modified HTML to extract clean text
        var tempDoc = parse('<div>$htmlContent</div>');
        var cleanText = tempDoc.body?.text ?? '';

        // Clean up the text
        List<String> lines = cleanText.split('\n');
        List<String> cleanLines = [];

        for (String line in lines) {
          String cleanLine = line.trim();
          // Skip empty lines and lines that are just whitespace
          if (cleanLine.isNotEmpty) {
            cleanLines.add(cleanLine);
          }
        }

        final lyrics = cleanLines.join('\n');

        if (lyrics.isNotEmpty) {
          log('Successfully extracted lyrics');
          log('Total lines: ${cleanLines.length}');
          log('Lyrics length: ${lyrics.length} characters');
          log(
            'First 200 characters: ${lyrics.length > 200 ? lyrics.substring(0, 200) + "..." : lyrics}',
          );
          return lyrics;
        }
      }

      // Fallback: try to get all paragraphs
      var paragraphs = container.querySelectorAll('p');
      if (paragraphs.isNotEmpty) {
        log('Fallback: Found ${paragraphs.length} paragraph elements');

        final lyrics = paragraphs
            .map((p) {
              var htmlContent = p.innerHtml;
              if (htmlContent.isEmpty) {
                return p.text.trim();
              }
              htmlContent = htmlContent.replaceAll(
                RegExp(r'<br\s*/?>', caseSensitive: false),
                '\n',
              );
              var tempDoc = parse('<div>$htmlContent</div>');
              return tempDoc.body?.text?.trim() ?? '';
            })
            .where((text) => text.isNotEmpty)
            .join('\n\n');

        if (lyrics.isNotEmpty) {
          log(
            'Fallback extraction successful, lyrics length: ${lyrics.length}',
          );
          return lyrics;
        }
      }

      log('No lyrics found in container');
      return null;
    } catch (e) {
      log('Error in _extractLyricsFromContainer: $e');
      return null;
    }
  }
}
