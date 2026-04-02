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
/// The rule inspects:
/// - `InstanceCreationExpression` arguments that begin with `.`
/// - `MethodInvocation` arguments that begin with `.`
/// - `PrefixedIdentifier` arguments that begin with `.`
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
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _checkForNestedShorthands(node, node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Only care about method invocations that are themselves shorthands,
    // i.e. the target is null and the method name starts the expression
    // (dot shorthand like `.named(args)`).
    _checkForNestedShorthands(node, node.argumentList);
  }

  /// If [parentNode] is itself a dot shorthand invocation, scan its
  /// [argumentList] for arguments that are also dot shorthands.
  void _checkForNestedShorthands(Expression parentNode, ArgumentList args) {
    // First, verify the parent expression is a dot shorthand.
    // A dot shorthand in source starts with `.` — we detect this by
    // checking if the expression's source begins with a dot token.
    if (!_isDotShorthand(parentNode)) return;

    for (final argument in args.arguments) {
      // Unwrap named expressions: `foo(name: .value)`
      final expr = argument is NamedExpression ? argument.expression : argument;

      if (_isDotShorthand(expr)) {
        rule.reportAtNode(expr);
      }
    }
  }

  /// Returns `true` if [node] appears to be a dot shorthand expression.
  ///
  /// Detection strategy: a dot shorthand in resolved AST is an
  /// `InstanceCreationExpression`, `MethodInvocation`, or
  /// `PrefixedIdentifier` whose source text starts with `.`.
  ///
  /// We use the token offset: if the first token of the expression is
  /// a period (`.`), it's a shorthand.
  bool _isDotShorthand(Expression node) {
    final firstToken = node.beginToken;
    // In dot shorthand syntax, the very first token is a `.`
    // For `InstanceCreationExpression`: `.new(...)` or `.named(...)`
    //   beginToken is `.`
    // For `PrefixedIdentifier` shorthand: `.value`
    //   beginToken is `.`
    return firstToken.lexeme == '.';
  }
}
