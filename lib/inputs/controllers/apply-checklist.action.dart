import 'package:flutter/cupertino.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../documents/models/attributes/attributes-aliases.model.dart';
import '../../documents/models/attributes/attributes.model.dart';
import '../../documents/services/attribute.utils.dart';
import '../../shared/utils/intents.utils.dart';

class ApplyCheckListAction extends Action<ApplyCheckListIntent> {
  ApplyCheckListAction(this.controller);

  final EditorController controller;

  // TODO Make it a shared method. It's used in multiple places.
  bool _getIsToggled() {
    final attrs = controller.getSelectionStyle().attributes;
    var attribute = controller.toolbarButtonToggler[AttributesM.list.key];

    if (attribute == null) {
      attribute = attrs?[AttributesM.list.key];
    } else {
      // checkbox tapping causes controller.selection to go to offset 0
      controller.toolbarButtonToggler.remove(AttributesM.list.key);
    }

    if (attribute == null) {
      return false;
    }
    return attribute.value == AttributesAliasesM.unchecked.value ||
        attribute.value == AttributesAliasesM.checked.value;
  }

  @override
  void invoke(ApplyCheckListIntent intent, [BuildContext? context]) {
    controller.formatSelection(_getIsToggled()
        ? AttributeUtils.clone(AttributesAliasesM.unchecked, null)
        : AttributesAliasesM.unchecked);
  }

  @override
  bool get isActionEnabled => true;
}
