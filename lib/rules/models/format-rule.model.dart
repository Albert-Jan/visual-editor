import '../models/rule-type.enum.dart';
import '../models/rule.model.dart';

// A heuristic rule for format (retain) operations.
abstract class FormatRuleM extends RuleM {
  const FormatRuleM();

  @override
  RuleTypeE get type => RuleTypeE.format;
}
