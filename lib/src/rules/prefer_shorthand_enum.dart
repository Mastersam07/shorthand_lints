import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../utils/context_type.dart';

/// Lint rule: prefer_dot_shorthand_for_enums
///
/// Flags fully-qualified enum value accesses like `Status.loading`
/// where the type context allows dot shorthand `.loading`.
///
/// ```dart
/// // BAD:
/// Status status = Status.loading;
///
/// // GOOD:
/// Status status = .loading;
/// ```
class PreferShorthandEnum extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_dot_shorthand_for_enums',
    'Enum value can use dot shorthand.',
    correctionMessage: "Try using '.{0}' instead of '{1}.{0}'.",
  );

  PreferShorthandEnum()
    : super(
        name: 'prefer_dot_shorthand_for_enums',
        description:
            'Prefer dot shorthand syntax for enum values when the '
            'type can be inferred from context.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry.addPrefixedIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    final prefixElement = node.prefix.element;

    // Only flag enum values
    if (!isEnumElement(prefixElement)) return;

    // Verify the identifier refers to an enum constant
    // (not a static method, getter, etc. — those go to the statics rule)
    final identifierElement = node.identifier.element;
    if (identifierElement is! FieldElement || !identifierElement.isEnumConstant) {
      return;
    }

    // Verify context type exists so shorthand would compile
    if (!hasTypeContext(node)) return;

    // Verify the prefix matches the resolved type
    if (!prefixMatchesType(prefixElement, node.staticType)) return;

    // Report at the prefix (the redundant part)
    rule.reportAtNode(node.prefix);
  }
}
