import 'package:flutter/cupertino.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../documents/models/attribute.model.dart';
import '../../documents/models/attributes/attributes.model.dart';
import '../../shared/utils/intents.utils.dart';

class ApplyHeaderAction extends Action<ApplyHeaderIntent> {
  ApplyHeaderAction(this.controller);

  final EditorController controller;

  // TODO Make it a shared method. Same method used in other parts too.
  AttributeM<dynamic> _getHeaderValue() {
    final attr = controller.toolbarButtonToggler[AttributesM.header.key];
    if (attr != null) {
      // Checkbox tapping causes controller.selection to go to offset 0
      controller.toolbarButtonToggler.remove(AttributesM.header.key);
      return attr;
    }
    return controller.getSelectionStyle().attributes?[AttributesM.header.key] ??
        AttributesM.header;
  }

  @override
  void invoke(ApplyHeaderIntent intent, [BuildContext? context]) {
    final _attribute =
    _getHeaderValue() == intent.header ? AttributesM.header : intent.header;
    controller.formatSelection(_attribute);
  }

  @override
  bool get isActionEnabled => true;
}
