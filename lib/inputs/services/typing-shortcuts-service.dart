import 'package:flutter/material.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../documents/models/attribute.model.dart';
import '../../documents/models/attributes/attributes-aliases.model.dart';
import '../../documents/models/change-source.enum.dart';
import '../../documents/models/nodes/block.model.dart';
import '../../documents/models/nodes/line.model.dart';

class TypingShortcutsService {
  static final _instance = TypingShortcutsService._privateConstructor();

  factory TypingShortcutsService() => _instance;

  TypingShortcutsService._privateConstructor();

  KeyEventResult handleSpaceKey(EditorController controller, RawKeyEvent event) {
    final child = controller.document
        .queryChild(controller.selection.baseOffset);
    if (child.node == null) {
      return KeyEventResult.ignored;
    }

    final line = child.node as LineM?;
    if (line == null) {
      return KeyEventResult.ignored;
    }

    // Get the first 2 chars of a line.
    final text = line.getPlainText(0, 2);

    const olKeyPhrase = '1.';
    const ulKeyPhrase = '-';

    if (text == olKeyPhrase) {
      _updateSelectionForKeyPhrase(controller, olKeyPhrase, AttributesAliasesM.ol);
    } else if (text[0] == ulKeyPhrase) {
      _updateSelectionForKeyPhrase(controller, ulKeyPhrase, AttributesAliasesM.ul);
    } else {
      return KeyEventResult.ignored;
    }

    return KeyEventResult.handled;
  }

  KeyEventResult handleTabKey(EditorController controller, RawKeyEvent event) {
    final child = controller.document.queryChild(
      controller.selection.baseOffset,
    );
    final node = child.node!;
    final nodeParent = node.parent;

    // TODO Understand when this is used.
    if (child.node == null) {
      return _insertTabCharacter(controller);
    }

    if (nodeParent == null || nodeParent is! BlockM) {
      return event.isShiftPressed
          ? _removeTabCharacter(controller)
          : _insertTabCharacter(controller);
    }

    // Ordered lists, unordered lists, checked type line.
    if (nodeParent.style.containsKey(AttributesAliasesM.ol.key) ||
        nodeParent.style.containsKey(AttributesAliasesM.ul.key) ||
        nodeParent.style.containsKey(AttributesAliasesM.checked.key)) {
      controller.indentSelection(!event.isShiftPressed);
      return KeyEventResult.handled;
    }

    if (node is! LineM || (node.isNotEmpty && node.first is! String)) {
      return _insertTabCharacter(controller);
    }

    if (node.isNotEmpty && (node.first as String).isNotEmpty) {
      return _insertTabCharacter(controller);
    }

    return _insertTabCharacter(controller);
  }

  // === PRIVATE ===

  void _updateSelectionForKeyPhrase(EditorController controller, String phrase, AttributeM attribute) {
    controller
      ..formatSelection(attribute)
      ..replaceText(
        controller.selection.baseOffset - phrase.length,
        phrase.length,
        '',
        null,
      );

    // It is unclear why the selection moves forward the edit distance.
    // For indenting a bullet list we need to move the cursor with -1 and for ol with -2.
    attribute == AttributesAliasesM.ol ? _moveCursor(controller, -2) : _moveCursor(controller, -1);
  }

  // TODO When pressing shift + tab even though there aren't any tab char added
  // The logic is going to remove 4 chars before the charet. That's not what we intend.
  // One possible solution to this is to verify if there are 4 whitespaces before the charet.
  // If there are, apply this logic, else do not.
  KeyEventResult _removeTabCharacter(EditorController controller) {
    controller.replaceText(
      controller.selection.baseOffset - 4,
      4,
      '',
      null,
    );
    _moveCursor(controller, -4);
    return KeyEventResult.handled;
  }

  // Flutter doesn't add the \t character properly, so in order to add 4 whitespaces
  // we used a string.
  KeyEventResult _insertTabCharacter(EditorController controller) {
    const tab = '    ';

    controller.replaceText(
      controller.selection.baseOffset,
      0,
      tab,
      null,
    );
    _moveCursor(controller, 4);
    return KeyEventResult.handled;
  }

  void _moveCursor(EditorController controller, int chars) {
    final selection = controller.selection;
    controller.updateSelection(
      controller.selection.copyWith(
          baseOffset: selection.baseOffset + chars,
          extentOffset: selection.baseOffset + chars),
      ChangeSource.LOCAL,
    );
  }
}
