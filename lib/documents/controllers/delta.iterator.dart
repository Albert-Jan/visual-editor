import 'dart:math' as math;

import '../models/delta/delta.model.dart';
import '../models/delta/operation.model.dart';

// TODO Add better explanatory comment.
// Specialized iterator for DeltaMs.
class DeltaIterator {
  DeltaIterator(this.delta) : _modificationCount = delta.modificationCount;

  // Todo Explain why
  static const int maxLength = 1073741824;

  final DeltaM delta;
  final int _modificationCount;
  int _index = 0;
  int _offset = 0;

  bool get isNextInsert => nextOperationKey == OperationM.insertKey;

  bool get isNextDelete => nextOperationKey == OperationM.deleteKey;

  bool get isNextRetain => nextOperationKey == OperationM.retainKey;

  String? get nextOperationKey {
    if (_index < delta.length) {
      return delta.operationAt(_index).key;
    } else {
      return null;
    }
  }

  bool get isNotLastOperation => peekLength() < maxLength;

  // Returns length of next operation without consuming it.
  // Returns maxLength if there is no more operations left to iterate.
  int peekLength() {
    if (_index < delta.length) {
      final operation = delta.operationAt(_index);
      return operation.length! - _offset;
    }

    return maxLength;
  }

  // Consumes and returns next operation.
  // Optional length specifies maximum length of operation to return. Note
  // that actual length of returned operation may be less than specified value.
  // If this iterator reached the end of the Delta then returns a retain
  // operation with its length set to maxLength.
  // TODO: Note that we used double.infinity as the default value
  // For length here but this can now cause a type error since operation length is expected to be an int.
  // Changing default length to maxLength is a workaround to avoid breaking changes.
  OperationM next([int length = maxLength]) {
    if (_modificationCount != delta.modificationCount) {
      throw ConcurrentModificationError(delta);
    }

    if (_index < delta.length) {
      final operation = delta.operationAt(_index);
      final operationKey = operation.key;
      final operationAttributes = operation.attributes;
      final _currentOffset = _offset;
      final actualLength = math.min(operation.length! - _currentOffset, length);

      if (actualLength == operation.length! - _currentOffset) {
        _index++;
        _offset = 0;
      } else {
        _offset += actualLength;
      }

      final opData = operation.isInsert && operation.data is String
          ? (operation.data as String)
              .substring(_currentOffset, _currentOffset + actualLength)
          : operation.data;
      final opIsNotEmpty =
          opData is String ? opData.isNotEmpty : true; // embeds are never empty
      final opLength = opData is String ? opData.length : 1;
      final opActualLength = opIsNotEmpty ? opLength : actualLength;

      return OperationM(
        operationKey,
        opActualLength,
        opData,
        operationAttributes,
      );
    }
    return OperationM.retain(length);
  }

  // Skips length characters in source delta.
  // Returns last skipped operation, or `null` if there was nothing to skip.
  OperationM? skip(int length) {
    var skipped = 0;
    OperationM? op;

    while (skipped < length && isNotLastOperation) {
      final opLength = peekLength();
      final skip = math.min(length - skipped, opLength);
      op = next(skip);
      skipped += op.length!;
    }
    return op;
  }
}
