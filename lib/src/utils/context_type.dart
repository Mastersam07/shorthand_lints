import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Determines whether an expression's parent provides sufficient
/// type context for dot shorthand to be valid.
///
/// Dot shorthand requires the compiler to infer the type from context.
/// This utility checks the surrounding AST to verify that context exists.
bool hasTypeContext(Expression node) {
  final parent = node.parent;
  if (parent == null) return false;

  // Variable declaration with explicit type annotation:
  //   Color c = Colors.blue;  →  Color c = .blue;
  if (parent is VariableDeclaration) {
    final declarationList = parent.parent;
    if (declarationList is VariableDeclarationList) {
      final declaredType = declarationList.type?.type;
      if (declaredType == null || declaredType is DynamicType) return false;
      return true;
    }
    return false;
  }

  // Assignment expression (right-hand side):
  //   c = Colors.blue;
  if (parent is AssignmentExpression && parent.rightHandSide == node) {
    return true;
  }

  // Named expression (function/constructor named argument):
  //   Container(color: Colors.blue)
  if (parent is NamedExpression) {
    return true;
  }

  // Positional argument in a function/constructor invocation:
  //   foo(Status.loading)  →  foo(.loading)
  if (parent is ArgumentList) {
    return true;
  }

  // Return statement in a function with a declared return type:
  //   Color getColor() => Colors.blue;
  if (parent is ReturnStatement || parent is ExpressionFunctionBody) {
    return true;
  }

  // Binary expression: right side of == or !=
  //   if (status == Status.loading)  →  if (status == .loading)
  if (parent is BinaryExpression &&
      parent.rightOperand == node &&
      (parent.operator.lexeme == '==' || parent.operator.lexeme == '!=')) {
    return true;
  }

  // Switch expression case / switch statement case:
  //   case Status.loading:  →  case .loading:
  if (parent is SwitchPatternCase || parent is SwitchCase) {
    return true;
  }

  // Guard pattern / constant pattern in switch expressions
  if (parent is ConstantPattern) {
    return true;
  }

  // Conditional expression (ternary) — both then and else branches:
  //   condition ? Status.loading : Status.error
  if (parent is ConditionalExpression && (parent.thenExpression == node || parent.elseExpression == node)) {
    // Context exists if the ternary itself has context, or
    // if the other branch provides type info. Simpler: the compiler
    // propagates context into both branches.
    return hasTypeContext(parent);
  }

  // Collection literal with explicit type arguments:
  //   <Status>[Status.loading]  →  <Status>[.loading]
  //   {Status.loading}
  if (parent is ListLiteral && parent.typeArguments != null) {
    return true;
  }
  if (parent is SetOrMapLiteral && parent.typeArguments != null) {
    return true;
  }

  // Collection element in a typed collection (handles spread, if, for):
  if (parent is ListLiteral || parent is SetOrMapLiteral) {
    // Even without explicit type args, the collection may have
    // a context type from its parent. We'll be conservative and
    // only flag when type args are explicit.
    return false;
  }

  // Map entry in a typed map literal:
  if (parent is MapLiteralEntry) {
    final grandparent = parent.parent;
    if (grandparent is SetOrMapLiteral && grandparent.typeArguments != null) {
      return true;
    }
    return false;
  }

  // Yield statement:
  //   yield Status.loading;
  if (parent is YieldStatement) {
    return true;
  }

  // Default parameter value:
  //   void foo({Status s = Status.loading})
  if (parent is DefaultFormalParameter) {
    return true;
  }

  // Field declaration with explicit type:
  //   final Color color = Colors.blue;
  // This is handled by VariableDeclaration above (fields are
  // also VariableDeclarations).

  // Initializer in a constructor initializer list:
  //   : color = Colors.blue
  if (parent is ConstructorFieldInitializer) {
    return true;
  }

  // Assert statement / assert initializer:
  //   assert(status == Status.loading)
  // Not a context — the assert expects bool. Skip.

  return false;
}

/// Checks if [prefixElement] refers to the same class/enum as
/// the given [type].
///
/// This is used to verify that the type prefix in `ClassName.member`
/// matches the resolved type, confirming dot shorthand would work.
bool prefixMatchesType(Element? prefixElement, DartType? type) {
  if (prefixElement == null || type == null) return false;

  // Get the element behind the type
  Element? typeElement;
  if (type is InterfaceType) {
    typeElement = type.element;
  }

  if (typeElement == null) return false;

  // Direct match
  if (prefixElement == typeElement) return true;

  // The prefix might be the class itself, or a type alias.
  // For now, direct element comparison is sufficient.
  return false;
}

/// Returns true if [element] refers to an enum constant.
///
/// The element may be a [FieldElement] directly, or a
/// [PropertyAccessorElement] (synthetic getter) wrapping one.
bool isEnumConstantElement(Element? element) {
  if (element is FieldElement) return element.isEnumConstant;
  if (element is PropertyAccessorElement) {
    final variable = element.variable;
    return variable is FieldElement && variable.isEnumConstant;
  }
  return false;
}

/// Returns true if [element] is an enum declaration.
bool isEnumElement(Element? element) => element is EnumElement;

/// Returns true if [element] is a class or enum declaration
/// (i.e. can have static members or constructors).
bool isClassOrEnumElement(Element? element) => element is ClassElement || element is EnumElement;
