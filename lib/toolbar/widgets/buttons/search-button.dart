import 'package:flutter/material.dart';

import '../../../visual-editor.dart';

class SearchButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;

  // final EditorController controller;
  final EditorIconThemeM? iconTheme;
  final double buttonsSpacing;

  // late EditorState _state;

  const SearchButton({
    required this.buttonsSpacing,
    required this.icon,
    this.iconSize = 40,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconColor =
        iconTheme?.iconUnselectedColor ?? theme.iconTheme.color;
    final iconFillColor =
        iconTheme?.iconUnselectedFillColor ?? theme.canvasColor;

    return IconBtn(
      icon: Icon(icon, size: iconSize, color: iconColor),
      highlightElevation: 0,
      hoverElevation: 0,
      size: iconSize * 1.77,
      fillColor: iconFillColor,
      borderRadius: iconTheme?.borderRadius ?? 2,
      onPressed: () {},
      buttonsSpacing: 0,
    );
  }
}
