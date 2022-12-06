import 'package:flutter/material.dart';

// TODO Update comment.
// Used to output the rectangles of various text selections
// Ex: Highlights overlap multiple lines, therefore we need to extract multiple sets of markers
// from multiple lines and multiple styling fragments for one highlight.
@immutable
class SelectedLinkRectanglesM {
  // TODO Update comment if needed.
  // At initialisation the editor will parse the delta document and will start rendering the text lines one by one.
  // The rectangles and the relative position of the text line are useful for
  // rendering text attachments after the editor build is completed.
  // (!) Added at runtime
  final List<TextBox> rectangles;

  // Global position relative to the viewport of the EditableTextLine that contains the text selection.
  // We don't expose the full TextLine to avoid access from the public scope to the private scope.
  // (!) Added at runtime
  final Offset docRelPosition;

  const SelectedLinkRectanglesM({
    this.rectangles = const [],
    this.docRelPosition = Offset.zero,
  });

  @override
  String toString() {
    return 'SelectedLinkRectanglesM('
        'rectangles: $rectangles,'
        'docRelPosition: $docRelPosition,'
        ')';
  }

  SelectedLinkRectanglesM copyWith({
    List<TextBox>? rectangles,
    Offset? docRelPosition,
  }) =>
      SelectedLinkRectanglesM(
        rectangles: rectangles ?? this.rectangles,
        docRelPosition: docRelPosition ?? this.docRelPosition,
      );
}
