// TODO Add comment
class LinkMenuVisibilityState {
  bool _isVisible = false;

  bool get isVisible => _isVisible;

  void toggleLinkMenu(bool isVisible) {
    _isVisible = isVisible;
  }
}
