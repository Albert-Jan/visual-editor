import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../toolbar.dart';

// Button in the toolbar used to indent or unindent a selected area.
class IndentButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final EditorController controller;
  final bool isIndenting;
  final EditorIconThemeM? iconTheme;
  final double buttonsSpacing;

  const IndentButton({
    required this.icon,
    required this.controller,
    required this.buttonsSpacing,
    required this.isIndenting,
    this.iconSize = defaultIconSize,
    this.iconTheme,
    Key? key,
  }) : super(key: key);

  @override
  _IndentButtonState createState() => _IndentButtonState();
}

class _IndentButtonState extends State<IndentButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconColor =
        widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color;
    final iconFillColor =
        widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor;

    return IconBtn(
      highlightElevation: 0,
      hoverElevation: 0,
      size: widget.iconSize * 1.77,
      icon: Icon(
        widget.icon,
        size: widget.iconSize,
        color: iconColor,
      ),
      buttonsSpacing: widget.buttonsSpacing,
      fillColor: iconFillColor,
      borderRadius: widget.iconTheme?.borderRadius ?? 2,
      onPressed: () => widget.controller.indentSelection(widget.isIndenting),
    );
  }
}
