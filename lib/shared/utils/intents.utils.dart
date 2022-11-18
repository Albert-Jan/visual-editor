import 'package:flutter/material.dart';

import '../../documents/models/attribute.model.dart';

// TODO Should place them into multiple files and create a separated class util that holds them and can acess them from there?
// === INDENTATION ===

class IndentSelectionIntent extends Intent {
  const IndentSelectionIntent(this.isIncrease);

  final bool isIncrease;
}

// === HEADER ===

class ApplyHeaderIntent extends Intent {
  const ApplyHeaderIntent(this.header);

  final AttributeM header;
}

// === CHECKLIST ===

class ApplyCheckListIntent extends Intent {
  const ApplyCheckListIntent();
}

// === TEXT STYLE ===

class ToggleTextStyleIntent extends Intent {
  const ToggleTextStyleIntent(this.attribute);

  final AttributeM attribute;
}
