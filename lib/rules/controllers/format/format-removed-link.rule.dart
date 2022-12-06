import '../../../documents/controllers/delta.iterator.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/attributes/attributes.model.dart';
import '../../../documents/models/delta/delta.model.dart';
import '../../models/format-rule.model.dart';

// TODO Add doc comment.
class FormatRemovedLinkRule extends FormatRuleM {
  const FormatRemovedLinkRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    // Do nothing if it's not a removed link
    if (attribute!.key != AttributesM.removedLink.key) {
      return null;
    }
    final delta = DeltaM();
    final itr = DeltaIterator(document)..skip(index);
    final op = itr.next();

    // TODO Instead of delete, it should remove the link attribute from it. Find how to do it.
    if (op.hasAttribute(AttributesM.link.key)) {
      delta
        ..retain(index)
        ..delete(itr.hasNext ? len! : len! - 1);
    }

    return delta;
  }
}
