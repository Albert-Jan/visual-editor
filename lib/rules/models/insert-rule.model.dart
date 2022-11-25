import '../models/rule-type.enum.dart';
import '../models/rule.model.dart';

// A heuristic rule for insert operations.
abstract class InsertRuleM extends RuleM {
  const InsertRuleM();

  @override
  RuleTypeE get type => RuleTypeE.insert;
}
