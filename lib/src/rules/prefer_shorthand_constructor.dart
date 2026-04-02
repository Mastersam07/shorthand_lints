import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../utils/context_type.dart';

/// Lint rule: prefer_dot_shorthand_for_constructors
///
/// Flags constructor invocations like `SomeClass()` or `SomeClass.named()`
/// where the type context allows dot shorthand `.new()` or `.named()`.
///
/// ```dart
/// // BAD:
/// final ScrollController controller = ScrollController();
///
/// // GOOD:
/// final ScrollController controller = .new();
///
/// // BAD:
/// final Point p = Point.origin();
///
/// // GOOD:
/// final Point p = .origin();
/// ```
class PreferShorthandConstructor extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_dot_shorthand_for_constructors',
    'Constructor call can use dot shorthand.',
    correctionMessage: "Try using '.{0}' instead of the fully-qualified constructor.",
  );

  PreferShorthandConstructor()
    : super(
        name: 'prefer_dot_shorthand_for_constructors',
        description:
            'Prefer dot shorthand syntax for constructor calls when '
            'the type can be inferred from context.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Verify context type exists
    if (!hasTypeContext(node)) return;

    final constructorName = node.constructorName;
    final type = constructorName.type;

    // Get the class/enum element being constructed
    final constructedType = type.type;
    if (constructedType is! InterfaceType) return;

    final classElement = constructedType.element;

    // Verify the constructed type matches the context type exactly.
    // Dot shorthand `.new()` resolves against the context type, so
    // `Animal a = Dog()` cannot become `Animal a = .new()` — that
    // would call Animal(), not Dog().
    final contextType = getContextType(node);
    if (contextType != null) {
      if (!prefixMatchesType(classElement, contextType)) return;
    }

    // The type name is the redundant prefix — report on it.
    // For `SomeClass()`, the fix is `.new()`.
    // For `SomeClass.named()`, the fix is `.named()`.
    final name = constructorName.name?.name ?? 'new';
    rule.reportAtNode(type, arguments: [name]);
  }
}
