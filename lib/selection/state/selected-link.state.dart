import '../../shared/models/selection-rectangles.model.dart';

// TODO Add comment.
class SelectedLinkState {
  // === SELECTED LINK RECTANGLES ===

  // TODO Update comment
  // Once the document is rendered in lines and blocks we extract from each line the selection rectangles.
  // Selection can span multiple lines, therefore we need for each line the document relative offset.
  List<SelectionRectanglesM> _selectedLinkRectangles = [];

  List<SelectionRectanglesM> get selectedLinkRectangles => _selectedLinkRectangles;

  void setSelectedLinkRectangles(List<SelectionRectanglesM> rectangles) =>
      _selectedLinkRectangles = rectangles;
}