import 'package:flutter/material.dart';

import 'base/text-boundary.model.dart';

// The document boundary is unique and is a constant function of the input position.
class DocumentBoundary extends TextBoundaryM {
  const DocumentBoundary(
    this.plainText,
  );

  @override
  final TextEditingValue plainText;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) =>
      const TextPosition(offset: 0);

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) => TextPosition(
        offset: plainText.text.length,
        affinity: TextAffinity.upstream,
      );
}
