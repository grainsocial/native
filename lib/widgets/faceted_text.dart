import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class FacetedText extends StatelessWidget {
  final String text;
  final List<Map<String, dynamic>>? facets;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final void Function(String did)? onMentionTap;
  final void Function(String url)? onLinkTap;
  final void Function(String tag)? onTagTap;

  const FacetedText({
    super.key,
    required this.text,
    this.facets,
    this.style,
    this.linkStyle,
    this.onMentionTap,
    this.onLinkTap,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = style ?? theme.textTheme.bodyMedium;
    final defaultLinkStyle =
        linkStyle ??
        defaultStyle?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        );
    if (facets == null || facets!.isEmpty) {
      return Text(text, style: defaultStyle);
    }
    // Build a list of all ranges (start, end, type, data)
    final List<_FacetRange> ranges = facets!.map((facet) {
      final feature = facet['features']?[0] ?? {};
      final type = feature['\$type'] ?? feature['type'];
      return _FacetRange(
        start: facet['index']?['byteStart'] ?? facet['byteStart'] ?? 0,
        end: facet['index']?['byteEnd'] ?? facet['byteEnd'] ?? 0,
        type: type,
        data: feature,
      );
    }).toList();
    ranges.sort((a, b) => a.start.compareTo(b.start));
    int pos = 0;
    final spans = <TextSpan>[];
    for (final range in ranges) {
      if (range.start > pos) {
        spans.add(TextSpan(text: text.substring(pos, range.start), style: defaultStyle));
      }
      final content = text.substring(range.start, range.end);
      if (range.type?.contains('mention') == true && range.data['did'] != null) {
        spans.add(
          TextSpan(
            text: content,
            style: defaultLinkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = onMentionTap != null ? () => onMentionTap!(range.data['did']) : null,
          ),
        );
      } else if (range.type?.contains('link') == true && range.data['uri'] != null) {
        spans.add(
          TextSpan(
            text: content,
            style: defaultLinkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = onLinkTap != null ? () => onLinkTap!(range.data['uri']) : null,
          ),
        );
      } else if (range.type?.contains('tag') == true && range.data['tag'] != null) {
        spans.add(
          TextSpan(
            text: '#${range.data['tag']}',
            style: defaultLinkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = onTagTap != null ? () => onTagTap!(range.data['tag']) : null,
          ),
        );
      } else {
        spans.add(TextSpan(text: content, style: defaultStyle));
      }
      pos = range.end;
    }
    if (pos < text.length) {
      spans.add(TextSpan(text: text.substring(pos), style: defaultStyle));
    }
    return RichText(text: TextSpan(children: spans));
  }
}

class _FacetRange {
  final int start;
  final int end;
  final String? type;
  final Map<String, dynamic> data;
  _FacetRange({required this.start, required this.end, required this.type, required this.data});
}
