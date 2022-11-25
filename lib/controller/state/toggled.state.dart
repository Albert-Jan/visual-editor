import '../../documents/models/style.model.dart';

// Store any styles attribute that got toggled by the tap of a button and that has not been applied yet.
// It gets reset after each format action within the document.
// One example of this toggled style is that when you want to start writing with bold letters
// it is responsible for knowing to use bold and not plain text. (WIP Docs).
class ToggledState {
  StyleM _toggledStyle = StyleM();

  StyleM get toggledStyle => _toggledStyle;

  void setToggledStyle(StyleM toggledStyle) => _toggledStyle = toggledStyle;
}
