import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class FacetRange {
  final int start;
  final int end;
  final String? type;
  final Map<String, dynamic> data;

  FacetRange({required this.start, required this.end, required this.type, required this.data});
}

class ProcessedSpan {
  final int start;
  final int end;
  final TextSpan span;

  ProcessedSpan({required this.start, required this.end, required this.span});
}

class FacetUtils {
  /// Processes facets and returns a list of TextSpans with proper highlighting
  static List<TextSpan> processFacets({
    required String text,
    required List<Map<String, dynamic>>? facets,
    required TextStyle? defaultStyle,
    required TextStyle? linkStyle,
    void Function(String did)? onMentionTap,
    void Function(String url)? onLinkTap,
    void Function(String tag)? onTagTap,
  }) {
    if (facets == null || facets.isEmpty) {
      return [TextSpan(text: text, style: defaultStyle)];
    }

    // Build a list of all ranges (start, end, type, data)
    final List<FacetRange> ranges = facets.map((facet) {
      final feature = facet['features']?[0] ?? {};
      final type = feature['\$type'] ?? feature['type'];
      return FacetRange(
        start: facet['index']?['byteStart'] ?? facet['byteStart'] ?? 0,
        end: facet['index']?['byteEnd'] ?? facet['byteEnd'] ?? 0,
        type: type,
        data: feature,
      );
    }).toList();

    // Sort ranges by the length of their display text (longest first) to avoid overlap issues
    ranges.sort((a, b) {
      int aLength = a.end - a.start;
      int bLength = b.end - b.start;

      // For links, use the display text length
      if (a.type?.contains('link') == true && a.data['uri'] != null) {
        String displayText = a.data['uri'] as String;
        displayText = _extractDisplayTextFromUri(displayText);
        aLength = displayText.length;
      }

      if (b.type?.contains('link') == true && b.data['uri'] != null) {
        String displayText = b.data['uri'] as String;
        displayText = _extractDisplayTextFromUri(displayText);
        bLength = displayText.length;
      }

      // Sort by length descending, then by start position ascending
      final lengthComparison = bLength.compareTo(aLength);
      return lengthComparison != 0 ? lengthComparison : a.start.compareTo(b.start);
    });

    final List<ProcessedSpan> processedSpans = <ProcessedSpan>[];
    final Set<int> usedPositions = <int>{}; // Track which character positions are already used

    for (final range in ranges) {
      // For links, we need to find the actual text in the original text
      // since the facet positions might be based on the full URL with protocol
      String? actualContent;
      int actualStart = range.start;
      int actualEnd = range.end;

      if (range.type?.contains('link') == true && range.data['uri'] != null) {
        final uri = range.data['uri'] as String;
        final displayText = _extractDisplayTextFromUri(uri);

        // Find all occurrences of this text and pick the one that doesn't overlap with used positions
        int searchIndex = 0;
        bool foundValidMatch = false;

        while (!foundValidMatch) {
          final globalIndex = text.indexOf(displayText, searchIndex);
          if (globalIndex == -1) break;

          // Check if this range overlaps with any used positions
          bool overlaps = false;
          for (int i = globalIndex; i < globalIndex + displayText.length; i++) {
            if (usedPositions.contains(i)) {
              overlaps = true;
              break;
            }
          }

          if (!overlaps) {
            actualStart = globalIndex;
            actualEnd = globalIndex + displayText.length;
            actualContent = displayText;
            foundValidMatch = true;

            // Mark these positions as used
            for (int i = actualStart; i < actualEnd; i++) {
              usedPositions.add(i);
            }
          } else {
            searchIndex = globalIndex + 1;
          }
        }
      }

      // Handle other facet types that might have similar issues
      if (actualContent == null) {
        // Verify the range is within bounds
        if (range.start >= 0 && range.end <= text.length && range.start < range.end) {
          actualContent = text.substring(range.start, range.end);
          actualStart = range.start;
          actualEnd = range.end;

          // Check if this overlaps with used positions
          bool overlaps = false;
          for (int i = actualStart; i < actualEnd; i++) {
            if (usedPositions.contains(i)) {
              overlaps = true;
              break;
            }
          }

          if (!overlaps) {
            // Mark these positions as used
            for (int i = actualStart; i < actualEnd; i++) {
              usedPositions.add(i);
            }
          } else {
            // Skip overlapping ranges
            actualContent = null;
          }
        } else {
          // Skip invalid ranges
          continue;
        }
      }

      if (actualContent != null) {
        TextSpan span;
        if (range.type?.contains('mention') == true && range.data['did'] != null) {
          span = TextSpan(
            text: actualContent,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = onMentionTap != null ? () => onMentionTap(range.data['did']) : null,
          );
        } else if (range.type?.contains('link') == true && range.data['uri'] != null) {
          span = TextSpan(
            text: actualContent,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = onLinkTap != null ? () => onLinkTap(range.data['uri']) : null,
          );
        } else if (range.type?.contains('tag') == true && range.data['tag'] != null) {
          span = TextSpan(
            text: '#${range.data['tag']}',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = onTagTap != null ? () => onTagTap(range.data['tag']) : null,
          );
        } else {
          span = TextSpan(text: actualContent, style: defaultStyle);
        }

        processedSpans.add(ProcessedSpan(start: actualStart, end: actualEnd, span: span));
      }
    }

    // Sort processed spans by position and build final spans list
    processedSpans.sort((a, b) => a.start.compareTo(b.start));
    int pos = 0;
    final spans = <TextSpan>[];

    for (final processedSpan in processedSpans) {
      if (processedSpan.start > pos) {
        spans.add(TextSpan(text: text.substring(pos, processedSpan.start), style: defaultStyle));
      }
      spans.add(processedSpan.span);
      pos = processedSpan.end;
    }

    if (pos < text.length) {
      spans.add(TextSpan(text: text.substring(pos), style: defaultStyle));
    }

    return spans;
  }

  /// Extracts the display text from a URI (removes protocol but keeps subdomain, removes path)
  static String _extractDisplayTextFromUri(String uri) {
    String displayText = uri;
    if (uri.startsWith('https://')) {
      displayText = uri.substring(8);
    } else if (uri.startsWith('http://')) {
      displayText = uri.substring(7);
    }
    // Remove path but keep subdomain (everything before the first slash after protocol)
    final slashIndex = displayText.indexOf('/');
    if (slashIndex != -1) {
      displayText = displayText.substring(0, slashIndex);
    }
    return displayText;
  }
}
