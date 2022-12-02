import '../../documents/controllers/delta.iterator.dart';
import '../../documents/models/delta/operation.model.dart';
import 'new-operartion.model.dart';

NewOperationM getNextNewLine(DeltaIterator iterator) {
  OperationM operation;

  for (var skipped = 0; iterator.isNotLastOperation; skipped += operation.length!) {
    operation = iterator.next();
    final lineBreak =
        (operation.data is String ? operation.data as String? : '')!
            .indexOf('\n');

    if (lineBreak >= 0) {
      return NewOperationM(operation, skipped);
    }
  }

  return NewOperationM(null, null);
}
