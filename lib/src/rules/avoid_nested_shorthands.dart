import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Lint rule: avoid_nested_shorthands
///
/// Warns when a dot shorthand invocation has an argument that is also
/// a dot shorthand. Nested shorthands reduce readability to the point
/// where everything becomes `.new(.new(...))`.
///
/// ```dart
/// // BAD:
/// final Another a = .new(.new(version: .new('val')));
///
/// // GOOD:
/// final Another a = .new(Some(version: SomeClass('val')));
/// ```
///
/// Only the **inner** shorthand is flagged so the developer can decide
/// which level to expand, while the outermost shorthand stays concise.
class AvoidNestedShorthands extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_nested_shorthands',
    'Avoid nested dot shorthands as they significantly reduce readability.',
    correctionMessage: 'Try adding explicit types to inner shorthand arguments.',
  );

  AvoidNestedShorthands()
    : super(
        name: 'avoid_nested_shorthands',
        description:
            'Warns when a dot shorthand expression contains arguments '
            'that are also dot shorthands, which hurts readability.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry.addDotShorthandInvocation(this, visitor);
    registry.addDotShorthandConstructorInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) => _checkArguments(node.argumentList);

  @override
  void visitDotShorthandConstructorInvocation(DotShorthandConstructorInvocation node) =>
      _checkArguments(node.argumentList);

  void _checkArguments(ArgumentList args) {
    for (final argument in args.arguments) {
      final expr = switch (argument) {
        NamedExpression(:var expression) => expression,
        _ => argument,
      };

      if (expr is DotShorthandInvocation ||
          expr is DotShorthandConstructorInvocation ||
          expr is DotShorthandPropertyAccess) {
        rule.reportAtNode(expr);
      }
    }
  }
}
