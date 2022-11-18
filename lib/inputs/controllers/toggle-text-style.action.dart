import 'package:flutter/cupertino.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../documents/models/attribute.model.dart';
import '../../documents/models/attributes/attributes.model.dart';
import '../../documents/services/attribute.utils.dart';
import '../../shared/utils/intents.utils.dart';

// Toggles a text style (underline, bold, italic, strikethrough) on, or off.
class ToggleTextStyleAction extends Action<ToggleTextStyleIntent> {
  ToggleTextStyleAction(this.controller);

  final EditorController controller;

  bool _isStyleActive(AttributeM styleAttr, Map<String, AttributeM> attrs) {
    if (styleAttr.key == AttributesM.list.key) {
      final attribute = attrs[styleAttr.key];
      if (attribute == null) {
        return false;
      }
      return attribute.value == styleAttr.value;
    }
    return attrs.containsKey(styleAttr.key);
  }

  @override
  void invoke(ToggleTextStyleIntent intent, [BuildContext? context]) {
    final isActive = _isStyleActive(
        intent.attribute, controller.getSelectionStyle().attributes!);
    controller.formatSelection(
      isActive
          ? AttributeUtils.clone(intent.attribute, null)
          : intent.attribute,
    );
  }

  @override
  bool get isActionEnabled => true;
}
