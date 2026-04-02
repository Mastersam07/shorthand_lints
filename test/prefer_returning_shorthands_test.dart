// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:shorthand_lints/src/rules/prefer_returning_shorthands.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferReturningShorthandsTest);
  });
}

@reflectiveTest
class PreferReturningShorthandsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferReturningShorthands();
    super.setUp();
  }

  // Should lint

  void test_returnStatement_enumValue() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

Status f() {
  return Status.success;
}
''',
      [lint(69, 6)],
    );
  }

  void test_expressionBody_enumValue() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

Status f() => Status.error;
''',
      [lint(61, 6)],
    );
  }

  void test_returnStatement_namedConstructor() async {
    await assertDiagnostics(
      r'''
class Point {
  final double x, y;
  Point(this.x, this.y);
  Point.origin() : x = 0, y = 0;
}

Point f() {
  return Point.origin();
}
''',
      [lint(117, 5)],
    );
  }

  void test_returnStatement_unnamedConstructor() async {
    await assertDiagnostics(
      r'''
class Point {
  final double x, y;
  Point(this.x, this.y);
}

Point f() {
  return Point(1, 2);
}
''',
      [lint(84, 5)],
    );
  }

  void test_expressionBody_constructor() async {
    await assertDiagnostics(
      r'''
class Point {
  final double x, y;
  Point(this.x, this.y);
  Point.origin() : x = 0, y = 0;
}

Point f() => Point.origin();
''',
      [lint(109, 5)],
    );
  }

  void test_returnStatement_staticConst() async {
    await assertDiagnostics(
      r'''
class AppColors {
  static const AppColors primary = AppColors._(0xFF);
  final int value;
  const AppColors._(this.value);
}

AppColors f() {
  return AppColors.primary;
}
''',
      [lint(152, 9)],
    );
  }

  void test_methodDeclaration() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

class Service {
  Status getStatus() {
    return Status.idle;
  }
}
''',
      [lint(97, 6)],
    );
  }

  void test_asyncFunction_unwrapsFuture() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

Future<Status> f() async {
  return Status.loading;
}
''',
      [lint(83, 6)],
    );
  }

  // Should NOT lint

  void test_noLint_noReturnTypeAnnotation() async {
    await assertNoDiagnostics(r'''
enum Status { idle, loading, success, error }

f() {
  return Status.loading;
}
''');
  }

  void test_noLint_expressionBody_noReturnType() async {
    await assertNoDiagnostics(r'''
enum Status { idle, loading, success, error }

f() => Status.loading;
''');
  }

  void test_noLint_typeMismatch() async {
    // Returning a value whose prefix class doesn't match the return type.
    await assertNoDiagnostics(r'''
class Spacing {
  static const double small = 8.0;
}

double f() {
  return Spacing.small;
}
''');
  }

  void test_noLint_functionExpression() async {
    // Lambda assigned to a typed variable — the prefer_shorthand rules
    // handle the variable declaration, not the returning rule.
    await assertNoDiagnostics(r'''
enum Status { idle, loading, success, error }

void f() {
  final fn = () {
    return Status.idle;
  };
}
''');
  }

  void test_noLint_dynamicReturnType() async {
    await assertNoDiagnostics(r'''
enum Status { idle, loading, success, error }

dynamic f() {
  return Status.loading;
}
''');
  }
}
