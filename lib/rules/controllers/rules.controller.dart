import '../../../documents/models/attribute.model.dart';
import '../../../documents/models/document.model.dart';
import '../../../rules/models/rule-type.enum.dart';
import '../../documents/models/delta/delta.model.dart';
import '../models/rule.model.dart';
import 'delete/catch-all-delete.rule.dart';
import 'delete/ensure-embed-line.rule.dart';
import 'delete/ensure-last-line-break-delete.rule.dart';
import 'delete/preserve-line-style-on-merge.rule.dart';
import 'format/format-link-at-caret-position.rule.dart';
import 'format/resolve-block-format.rule.dart';
import 'format/resolve-image-format.rule.dart';
import 'format/resolve-inline-format.rule.dart';
import 'insert/auto-exit-block.rule.dart';
import 'insert/auto-format-links.rule.dart';
import 'insert/auto-format-multiple-links.rule.dart';
import 'insert/catch-all-insert.rule.dart';
import 'insert/insert-embeds.rule.dart';
import 'insert/preserve-block-style-on-insert.rule.dart';
import 'insert/preserve-inline-styles.rule.dart';
import 'insert/preserve-line-style-on-split.rule.dart';
import 'insert/reset-line-format-on-new-line.rule.dart';

// Each editor can have it's own set of rules.
// Therefore this is not a singleton class.
class RulesController {
  RulesController(this._rules);

  List<RuleM> _customRules = [];
  final List<RuleM> _rules;

  static final RulesController _instance = RulesController([
    const FormatLinkAtCaretPositionRule(),
    const ResolveBlockFormatRule(),
    const ResolveInlineFormatRule(),
    const ResolveImageFormatRule(),
    const InsertEmbedsRule(),
    const AutoExitBlockRule(),
    const PreserveBlockStyleOnInsertRule(),
    const PreserveLineStyleOnSplitRule(),
    const ResetLineFormatOnNewLineRule(),
    const AutoFormatLinksRule(),
    const AutoFormatMultipleLinksRule(),
    const PreserveInlineStylesRule(),
    const CatchAllInsertRule(),
    const EnsureEmbedLineRule(),
    const PreserveLineStyleOnMergeRule(),
    const CatchAllDeleteRule(),
    const EnsureLastLineBreakDeleteRule()
  ]);

  static RulesController getInstance() => _instance;

  void setCustomRules(List<RuleM> customRules) {
    _customRules = customRules;
  }

  // Loop through each rule in _customRules and _rules and if it has the same
  // type as the given rule type apply the rule.
  DeltaM applyRulesByType(
    RuleTypeE ruleType,
    DocumentM document,
    int index, {
    int? len,
    Object? data,
    AttributeM? attribute,
  }) {
    final delta = document.toDelta();

    for (final rule in _customRules + _rules) {
      // Continue if types are not the same.
      if (rule.type != ruleType) {
        continue;
      }

      try {
        final appliedRule = rule.applyRule(
          delta,
          index,
          len: len,
          data: data,
          attribute: attribute,
        );

        if (appliedRule != null) {
          return appliedRule..trim();
        }
      } catch (e) {
        rethrow;
      }
    }

    throw 'Applying rules failed';
  }
}
