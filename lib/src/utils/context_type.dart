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

  // Right side of == or !=
  BinaryExpression(:var rightOperand, :var operator)
      when rightOperand == node && (operator.lexeme == '==' || operator.lexeme == '!=') =>
    true,

  // Switch case
  SwitchPatternCase() || SwitchCase() || ConstantPattern() => true,

  // Ternary — context propagates into both branches
  ConditionalExpression(:var thenExpression, :var elseExpression)
      when thenExpression == node || elseExpression == node =>
    hasTypeContext(node.parent! as Expression),

  // Typed collection literals
  ListLiteral(typeArguments: _?) => true,
  SetOrMapLiteral(typeArguments: _?) => true,

  // Map entry in a typed map literal
  MapLiteralEntry(:var parent) => parent is SetOrMapLiteral && parent.typeArguments != null,

  // Yield, default parameter, constructor field initializer
  YieldStatement() || DefaultFormalParameter() || ConstructorFieldInitializer() => true,

  _ => false,
};

/// Checks if [prefixElement] refers to the same class/enum as
/// the given [type].
///
/// This is used to verify that the type prefix in `ClassName.member`
/// matches the resolved type, confirming dot shorthand would work.
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

/// Returns true if [element] is an enum declaration.
bool isEnumElement(Element? element) => element is EnumElement;

/// Returns true if [element] is a class or enum declaration
/// (i.e. can have static members or constructors).
bool isClassOrEnumElement(Element? element) => element is ClassElement || element is EnumElement;
