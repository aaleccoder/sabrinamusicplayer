/// A utility class for parsing LRC (Lyric) format lyrics
class LrcParser {
  /// Parses LRC format lyrics into a list of timed lyric lines
  static List<LrcLine> parse(String lrcContent) {
    final lines = <LrcLine>[];
    final lrcLines = lrcContent.split('\n');

    for (final line in lrcLines) {
      final match = RegExp(
        r'\[(\d{2}):(\d{2})\.(\d{2})\](.*)',
      ).firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centiseconds = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();

        final duration = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: centiseconds * 10,
        );

        lines.add(LrcLine(timestamp: duration, text: text));
      }
    }

    // Sort by timestamp
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  /// Gets the index of the currently active lyric line based on current position
  static int getCurrentLineIndex(
    List<LrcLine> lines,
    Duration currentPosition,
  ) {
    if (lines.isEmpty) return -1;

    for (int i = lines.length - 1; i >= 0; i--) {
      if (currentPosition >= lines[i].timestamp) {
        return i;
      }
    }

    return -1;
  }
}

/// Represents a single line of lyrics with its timestamp
class LrcLine {
  final Duration timestamp;
  final String text;

  LrcLine({required this.timestamp, required this.text});
}
