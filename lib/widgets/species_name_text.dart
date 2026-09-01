import 'package:flutter/material.dart';
import '../models/species_name.dart';

/// Latín en cursiva y nombre común entre paréntesis, como en Cloud.
class SpeciesNameText extends StatelessWidget {
  final SpeciesName name;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign textAlign;

  const SpeciesNameText(
    this.name, {
    super.key,
    this.style,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign = TextAlign.start,
  });

  factory SpeciesNameText.raw(
    String raw, {
    Key? key,
    TextStyle? style,
    int maxLines = 2,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return SpeciesNameText(
      SpeciesName.parse(raw),
      key: key,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyMedium;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: name.scientific,
            style: base?.copyWith(fontStyle: FontStyle.italic),
          ),
          if (name.hasDistinctCommon)
            TextSpan(text: ' (${name.common})', style: base),
        ],
      ),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
