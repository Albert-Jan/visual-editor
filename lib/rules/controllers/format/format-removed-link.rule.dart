import '../../../document/controllers/delta.iterator.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../../document/models/delta/delta.model.dart';
import '../../../document/services/delta.utils.dart';
import '../../models/format-rule.model.dart';

// TODO Add doc comment.
class FormatRemovedLinkRule extends FormatRuleM {
  final _du = DeltaUtils();

  FormatRemovedLinkRule();

  @override
  DeltaM? applyRule(
      DeltaM docDelta,
      int index, {
        int? len,
        Object? data,
        AttributeM? attribute,
        String plainText = '',
      }) {
    // Do nothing if it's not a removed link
    if (attribute!.key != AttributesM.removedLink.key) {
      return null;
    }
    final changeDelta = DeltaM();
    final itr = DeltaIterator(docDelta)..skip(index);
    final op = itr.next();

    // TODO Instead of delete, it should remove the link attribute from it. Find how to do it.
    if (op.hasAttribute(AttributesM.link.key)) {
      _du
        ..retain(changeDelta, index)
        ..delete(changeDelta, itr.hasNext ? len! : len! - 1);
    }

    return changeDelta;
  }
}
