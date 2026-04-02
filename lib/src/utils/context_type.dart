import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Determines whether an expression's parent provides sufficient
/// type context for dot shorthand to be valid.
///
/// Dot shorthand requires the compiler to infer the type from context.
/// This utility checks the surrounding AST to verify that context exists.
bool hasTypeContext(Expression node) => switch (node.parent) {
  // Variable declaration with explicit type annotation
  VariableDeclaration(:var parent) => switch (parent) {
    VariableDeclarationList(:var type?) when type.type is! DynamicType => true,
    _ => false,
  },

  // Assignment expression (right-hand side)
  AssignmentExpression(:var rightHandSide) when rightHandSide == node => true,

  // Named or positional argument
  NamedExpression() || ArgumentList() => true,

  // Return statement / expression body
  ReturnStatement() || ExpressionFunctionBody() => true,

  // Right side of ==, !=, or ??
  BinaryExpression(:var rightOperand, :var operator)
      when rightOperand == node && (operator.lexeme == '==' || operator.lexeme == '!=' || operator.lexeme == '??') =>
    true,

  // Switch case
  SwitchPatternCase() || SwitchCase() || ConstantPattern() => true,

  // Ternary — context propagates into both branches
  ConditionalExpression(:var thenExpression, :var elseExpression)
      when thenExpression == node || elseExpression == node =>
    hasTypeContext(node.parent! as Expression),

  // Typed collection literals (explicit type args or inferred from context)
  ListLiteral(typeArguments: _?) => true,
  ListLiteral() && final list => hasTypeContext(list),
  SetOrMapLiteral(typeArguments: _?) => true,
  SetOrMapLiteral() && final setOrMap => hasTypeContext(setOrMap),

  // Map entry in a typed map literal
  MapLiteralEntry(:var parent) => switch (parent) {
    SetOrMapLiteral(typeArguments: _?) => true,
    SetOrMapLiteral() && final setOrMap => hasTypeContext(setOrMap),
    _ => false,
  },

  // Collection control flow elements (if/for/spread) — walk up to the enclosing collection
  IfElement() || ForElement() || SpreadElement() => _hasCollectionContext(node.parent!),

  // Yield, default parameter, constructor field initializer
  YieldStatement() || DefaultFormalParameter() || ConstructorFieldInitializer() => true,

  _ => false,
};

/// Returns the context type that the parent expects for [node], or `null`
/// if no usable context type exists.
///
/// This extracts the declared/expected type from the surrounding AST node,
/// as opposed to the expression's own resolved type.
DartType? getContextType(Expression node) {
  final param = node.correspondingParameter;
  if (param != null) return param.type;

  // For expressions inside named arguments, check the named expression's parameter
  if (node.parent is NamedExpression) {
    final namedParam = (node.parent! as NamedExpression).correspondingParameter;
    if (namedParam != null) return namedParam.type;
  }

  return switch (node.parent) {
    VariableDeclaration(:var parent) => switch (parent) {
      VariableDeclarationList(:var type?) => type.type,
      _ => null,
    },
    AssignmentExpression(:var writeType) => writeType,
    ConstructorFieldInitializer(:var fieldName) =>
      fieldName.element is FieldElement ? (fieldName.element! as FieldElement).type : null,
    BinaryExpression(:var leftOperand, :var rightOperand) when rightOperand == node => leftOperand.staticType,
    ReturnStatement() || ExpressionFunctionBody() => _getEnclosingReturnType(node),
    _ => null,
  };
}

/// Checks if [prefixElement] refers to the same class/enum as
/// the given [type].
///
/// This is used to verify that the type prefix in `ClassName.member`
/// matches the resolved type, confirming dot shorthand would work.
/// Walks up through nested [CollectionElement] nodes (if/for/spread)
/// to find the enclosing collection literal and check its type context.
bool _hasCollectionContext(AstNode node) => switch (node) {
  ListLiteral(typeArguments: _?) => true,
  ListLiteral() && final list => hasTypeContext(list),
  SetOrMapLiteral(typeArguments: _?) => true,
  SetOrMapLiteral() && final setOrMap => hasTypeContext(setOrMap),
  // Nested control flow: `[if (a) if (b) Status.idle]`
  IfElement(:var parent?) || ForElement(:var parent?) || SpreadElement(:var parent?) => _hasCollectionContext(parent),
  _ => false,
};

bool prefixMatchesType(Element? prefixElement, DartType? type) => switch ((prefixElement, type)) {
  (var prefix?, InterfaceType(:var element)) => prefix == element,
  _ => false,
};

/// Returns true if [element] refers to an enum constant.
///
/// The element may be a [FieldElement] directly, or a
/// [PropertyAccessorElement] (synthetic getter) wrapping one.
bool isEnumConstantElement(Element? element) => switch (element) {
  FieldElement(:var isEnumConstant) => isEnumConstant,
  PropertyAccessorElement(:var variable) => variable is FieldElement && variable.isEnumConstant,
  _ => false,
};

/// Walks up from [node] to find the enclosing function/method's
/// declared return type. Returns `null` if not explicitly annotated.
DartType? _getEnclosingReturnType(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    switch (current) {
      case FunctionDeclaration(:var returnType?):
        return returnType.type;
      case MethodDeclaration(:var returnType?):
        return returnType.type;
      case FunctionExpression() when current.parent is! FunctionDeclaration:
        return null;
    }
    current = current.parent;
  }
  return null;
}

/// Returns true if [element] is an enum declaration.
bool isEnumElement(Element? element) => element is EnumElement;

/// Returns true if [element] is a class or enum declaration
/// (i.e. can have static members or constructors).
bool isClassOrEnumElement(Element? element) => element is ClassElement || element is EnumElement;
