import 'package:flutter/cupertino.dart';

import '../../controller/controllers/editor-controller.dart';
import '../../shared/utils/intents.utils.dart';

class IndentSelectionAction extends Action<IndentSelectionIntent> {
  IndentSelectionAction(this.controller);

  final EditorController controller;

  @override
  void invoke(IndentSelectionIntent intent, [BuildContext? context]) {
    controller.indentSelection(
      intent.isIncrease,
    );
  }

  @override
  bool get isActionEnabled => true;
}
