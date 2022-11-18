import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../widgets/editor-renderer-inner.dart';

class VerticalCaretMovementRunController {
  VerticalCaretMovementRunController(
    this._renderer,
    this._currentTextPosition,
  );

  TextPosition _currentTextPosition;

  final EditorRendererInner _renderer;

  TextPosition get current {
    return _currentTextPosition;
  }

  bool moveNext() {
    _currentTextPosition = _renderer.getTextPositionBelow(_currentTextPosition);
    return true;
  }

  bool movePrevious() {
    _currentTextPosition = _renderer.getTextPositionAbove(_currentTextPosition);
    return true;
  }
}
