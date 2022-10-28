import 'package:flutter/material.dart';

import '../../documents/models/nodes/node.model.dart';
import '../../shared/state/editor.state.dart';
import 'link-action-menu.enum.dart';

// Used internally by widget layer.
typedef LinkActionPicker = Future<LinkMenuActionE> Function(
  NodeM linkNode,
  EditorState state,
);

typedef LinkActionPickerDelegate = Future<LinkMenuActionE> Function(
  BuildContext context,
  String link,
  NodeM node,
);
