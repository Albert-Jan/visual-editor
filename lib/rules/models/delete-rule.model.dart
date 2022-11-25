import '../models/rule-type.enum.dart';
import '../models/rule.model.dart';

// A heuristic rule for delete operations.
abstract class DeleteRuleM extends RuleM {
  const DeleteRuleM();

  @override
  RuleTypeE get type => RuleTypeE.delete;
}
