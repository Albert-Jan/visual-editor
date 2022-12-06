import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../documents/models/nodes/node.model.dart';
import '../../documents/models/attributes/attributes.model.dart';

// When the author attempt to edit a link we need to edit the entire link
// length regardless of how much from the link was selected.
// The link range is extracted by analysing which neighbouring nodes contain the same link attribute.
// Once we know the range of a link we can then apply the changes on the entire link, not only on the selected part.
TextRange getLinkRange(NodeM node) {
  var start = node.documentOffset;
  var length = node.length;
  var prev = node.previous;
  final hasAttr = node.style.attributes != null;
  final linkAttr = node.style.attributes?[AttributesM.link.key]!;

  if (hasAttr) {
    while (prev != null) {
      if (prev.style.attributes![AttributesM.link.key] == linkAttr) {
        start = prev.documentOffset;
        length += prev.length;
        prev = prev.previous;
      } else {
        break;
      }
    }

    var next = node.next;
    while (next != null) {
      if (next.style.attributes![AttributesM.link.key] == linkAttr) {
        length += next.length;
        next = next.next;
      } else {
        break;
      }
    }
  }

  return TextRange(
    start: start,
    end: start + length,
  );
}
