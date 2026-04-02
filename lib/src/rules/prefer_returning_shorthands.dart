import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Lint rule: prefer_returning_shorthands
///
/// Flags return statements where the returned expression uses a
/// fully-qualified type name that matches the function's return type,
/// meaning dot shorthand would work.
///
/// ```dart
/// // BAD:
/// Status getStatus() => Status.success;
/// Status getStatus() { return Status.success; }
///
/// // GOOD:
/// Status getStatus() => .success;
/// Status getStatus() { return .success; }
///
/// // BAD:
/// Point buildPoint() => Point.origin();
///
/// // GOOD:
/// Point buildPoint() => .origin();
/// ```
class PreferReturningShorthands extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_returning_shorthands',
    'Return value can use dot shorthand to match the return type.',
    correctionMessage: 'Try using dot shorthand instead of the explicit type prefix.',
  );

  PreferReturningShorthands()
    : super(
        name: 'prefer_returning_shorthands',
        description:
            'Prefer dot shorthand syntax in return statements when '
            'the instance type matches the enclosing function\'s '
            'return type.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry.addReturnStatement(this, visitor);
    registry.addExpressionFunctionBody(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression == null) return;

    final returnType = _getEnclosingReturnType(node);
    if (returnType == null) return;

    _checkExpression(expression, returnType);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    final expression = node.expression;

    final returnType = _getEnclosingReturnType(node);
    if (returnType == null) return;

    _checkExpression(expression, returnType);
  }

  /// Checks if [expression] uses a fully-qualified form that could be
  /// shortened given the expected [returnType].
  void _checkExpression(Expression expression, DartType returnType) {
    switch (expression) {
      // Enum value or static member: `return Status.loading;`
      case PrefixedIdentifier(:var prefix) when prefix.element is InterfaceElement:
        if (_elementMatchesType(prefix.element! as InterfaceElement, returnType)) {
          rule.reportAtNode(prefix);
        }

      // Constructor call: `return Point.origin();` or `return SomeClass();`
      case InstanceCreationExpression(:var constructorName) when constructorName.type.type is InterfaceType:
        final constructedType = constructorName.type.type! as InterfaceType;
        if (_elementMatchesType(constructedType.element, returnType)) {
          rule.reportAtNode(constructorName.type);
        }
    }
  }

  /// Walks up the AST from [node] to find the enclosing function's
  /// declared return type. Returns `null` if the return type is
  /// not explicitly annotated (we don't flag inferred return types
  /// since the developer chose not to annotate).
  DartType? _getEnclosingReturnType(AstNode node) {
    AstNode? current = node.parent;

    while (current != null) {
      switch (current) {
        case FunctionDeclaration(:var returnType?, :var functionExpression):
          return _unwrapFutureIfAsync(returnType.type, functionExpression.body);

        case MethodDeclaration(:var returnType?, :var body):
          return _unwrapFutureIfAsync(returnType.type, body);

        // Bail for lambdas — context comes from the variable, not the
        // function expression. The other prefer_shorthand rules handle those.
        case FunctionExpression() when current.parent is! FunctionDeclaration:
          return null;
      }

      current = current.parent;
    }

    return null;
  }

  /// If the function body is async and the declared return type is
  /// `Future<T>`, unwrap to `T` since `return value;` in an async
  /// function expects `T`, not `Future<T>`.
  DartType? _unwrapFutureIfAsync(DartType? type, FunctionBody body) {
    if (type == null) return null;

    final isAsync = body.isAsynchronous && !body.isGenerator;
    if (!isAsync) return type;

    // Unwrap Future<T> → T
    if (type is InterfaceType && type.isDartAsyncFuture) {
      final typeArgs = type.typeArguments;
      if (typeArgs.isNotEmpty) {
        return typeArgs.first;
      }
    }

    return type;
  }

  /// Checks if [element] (the prefix class/enum) matches [type].
  bool _elementMatchesType(InterfaceElement element, DartType type) => type is InterfaceType && type.element == element;
}
