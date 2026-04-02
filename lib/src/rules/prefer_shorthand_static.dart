import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../utils/context_type.dart';

/// Lint rule: prefer_dot_shorthand_for_statics
///
/// Flags fully-qualified static member access like `Colors.blue`
/// where the type context allows dot shorthand `.blue`.
///
/// This rule covers static fields, static getters, and static
/// constants that are NOT enum values (those are handled by
/// `prefer_dot_shorthand_for_enums`).
///
/// ```dart
/// // BAD:
/// Color color = Colors.blue;
///
/// // GOOD:
/// Color color = .blue;
/// ```
class PreferShorthandStatic extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_dot_shorthand_for_statics',
    'Static member access can use dot shorthand.',
    correctionMessage: "Try using '.{0}' instead of '{1}.{0}'.",
  );

  PreferShorthandStatic()
    : super(
        name: 'prefer_dot_shorthand_for_statics',
        description:
            'Prefer dot shorthand syntax for static field and '
            'getter access when the type can be inferred from context.',
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

    // Must be a class or enum element (the type prefix)
    if (!isClassOrEnumElement(prefixElement)) return;

    // Skip enum constants — handled by prefer_shorthand_enum
    final identifierElement = node.identifier.element;
    if (isEnumConstantElement(identifierElement)) {
      return;
    }

    // Must be a static member (field, getter, or method reference)
    if (identifierElement == null) return;
    if (identifierElement is! FieldElement &&
        identifierElement is! PropertyAccessorElement &&
        identifierElement is! MethodElement) {
      return;
    }

    // For FieldElement / PropertyAccessorElement, verify it's static
    if (identifierElement is FieldElement && !identifierElement.isStatic) {
      return;
    }
    if (identifierElement is PropertyAccessorElement && !identifierElement.isStatic) {
      return;
    }
    if (identifierElement is MethodElement && !identifierElement.isStatic) {
      return;
    }

    // Verify context type exists
    if (!hasTypeContext(node)) return;

    // Verify the prefix matches the resolved type
    if (!prefixMatchesType(prefixElement, node.staticType)) return;

    // Report at the prefix
    rule.reportAtNode(node.prefix, arguments: [node.identifier.name, node.prefix.name]);
  }
}
