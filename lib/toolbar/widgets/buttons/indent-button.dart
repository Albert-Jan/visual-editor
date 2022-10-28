import 'package:flutter/material.dart';

import '../../../blocks/models/indent-buttons-type.enum.dart';
import '../../../controller/controllers/editor-controller.dart';
import '../../../documents/models/attributes/attributes.model.dart';
import '../../../documents/services/attribute.utils.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../toolbar.dart';

// Button in the toolbar used to indent or unindent a selected area.
class IndentButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final EditorController controller;
  final IndentButtonsTypeE type;
  final EditorIconThemeM? iconTheme;
  final double buttonsSpacing;

  const IndentButton({
    required this.icon,
    required this.controller,
    required this.buttonsSpacing,
    required this.type,
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
      onPressed: _indent,
    );
  }

  void _indent() {
    final indent = widget.controller
        .getSelectionStyle()
        .attributes?[AttributesM.indent.key];

    // If it's not indented and the button is indent add indent level 1.
    if (indent == null) {
      if (widget.type == IndentButtonsTypeE.indent) {
        widget.controller.formatSelection(
          AttributeUtils.getIndentLevel(1),
        );
      }
      return;
    }

    // Prevent decrease bellow 1 when un-indenting and indent level is 1.
    // (!) Don't remove, otherwise it is going to return a red screen error when un-indenting multiple times.
    if (indent.value == 1 && widget.type == IndentButtonsTypeE.unindent) {
      widget.controller.formatSelection(
        AttributeUtils.clone(AttributeUtils.getIndentLevel(1), null),
      );
      return;
    }

    // Increase indent value when the button is indenting.
    if (widget.type == IndentButtonsTypeE.indent) {
      widget.controller.formatSelection(
        AttributeUtils.getIndentLevel(indent.value + 1),
      );
      return;
    }

    // Decrease when un-indenting.
    widget.controller.formatSelection(
      AttributeUtils.getIndentLevel(indent.value - 1),
    );
  }
}
