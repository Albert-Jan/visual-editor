import '../../../documents/controllers/delta.iterator.dart';
import '../../../documents/models/attribute-scope.enum.dart';
import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/delta/delta.model.dart';
import '../../../documents/models/delta/operation.model.dart';
import '../../models/format-rule.model.dart';

// Produces Delta with inline-level attributes applied to all characters except newlines.
// Some examples of inline attributes would be bold, italic, underline.
// By removing this method, every inline-level attribute will not work.
class ResolveInlineFormatRule extends FormatRuleM {
  const ResolveInlineFormatRule();

  @override
  DeltaM? applyRule(
    DeltaM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    // Don't change anything if the attribute scope is not INLINE.
    if (attribute!.scope != AttributeScope.INLINE) {
      return null;
    }

    final delta = DeltaM()..retain(index);
    final itr = DeltaIterator(document)..skip(index);
    OperationM op;

    for (var cur = 0; cur < len! && itr.isNotLastOperation; cur += op.length!) {
      op = itr.next(len - cur);
      final text = op.data is String ? (op.data as String?)! : '';
      var lineBreak = text.indexOf('\n');

      if (lineBreak < 0) {
        delta.retain(op.length!, attribute.toJson());
        continue;
      }

      var pos = 0;

      while (lineBreak >= 0) {
        delta
          ..retain(lineBreak - pos, attribute.toJson())
          ..retain(1);
        pos = lineBreak + 1;
        lineBreak = text.indexOf('\n', pos);
      }

      if (pos < op.length!) {
        delta.retain(op.length! - pos, attribute.toJson());
      }
    }

    return delta;
  }
}
