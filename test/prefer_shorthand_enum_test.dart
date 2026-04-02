// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:shorthand_lints/src/rules/prefer_shorthand_enum.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferShorthandEnumTest);
  });
}

@reflectiveTest
class PreferShorthandEnumTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferShorthandEnum();
    super.setUp();
  }

  // Should lint

  void test_variableDeclarationWithExplicitType() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

Status s = Status.loading;
''',
      [lint(58, 6)],
    );
  }

  void test_equalityRightSide() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void f(Status s) {
  if (s == Status.success) {}
}
''',
      [lint(77, 6)],
    );
  }

  void test_notEqualRightSide() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void f(Status s) {
  if (s != Status.error) {}
}
''',
      [lint(77, 6)],
    );
  }

  void test_namedArgument() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void render({required Status status}) {}

void f() {
  render(status: Status.idle);
}
''',
      [lint(117, 6)],
    );
  }

  void test_positionalArgument() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void render(Status status) {}

void f() {
  render(Status.idle);
}
''',
      [lint(98, 6)],
    );
  }

  void test_typedListLiteral() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void f() {
  var x = <Status>[Status.idle, Status.loading];
}
''',
      [lint(77, 6), lint(90, 6)],
    );
  }

  void test_typedListLiteral_inferredFromVariable() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void f() {
  List<Status> x = [Status.idle, Status.loading];
}
''',
      [lint(78, 6), lint(91, 6)],
    );
  }

  void test_defaultParameterValue() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void f({Status s = Status.idle}) {}
''',
      [lint(66, 6)],
    );
  }

  void test_constructorFieldInitializer() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

class MyClass {
  final Status status;
  MyClass() : status = Status.idle;
}
''',
      [lint(109, 6)],
    );
  }

  void test_returnStatement() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

Status f() {
  return Status.idle;
}
''',
      [lint(69, 6)],
    );
  }

  // Should NOT lint

  void test_noLint_varWithoutTypeAnnotation() async {
    await assertNoDiagnostics(r'''
enum Status { idle, loading, success, error }

void f() {
  var s = Status.loading;
}
''');
  }

  void test_noLint_dynamicContext() async {
    await assertNoDiagnostics(r'''
enum Status { idle, loading, success, error }

void f() {
  dynamic d = Status.loading;
}
''');
  }

  void test_noLint_leftSideOfEquality() async {
    // Shorthand on the left of == is a compile error, not our concern.
    // But we also shouldn't lint the left side — only the right.
    await assertNoDiagnostics(r'''
enum Status { idle, loading, success, error }

void f() {
  // This references the enum value itself, not in a shorthand context.
  var s = Status.idle;
  print(s);
}
''');
  }

  void test_noLint_staticMethodOnEnum() async {
    // A static method like Status.values shouldn't trigger the enum rule
    // because it's not an enum constant — it's handled by the statics rule.
    await assertNoDiagnostics(r'''
enum Status { idle, loading, success, error }

void f() {
  var v = Status.values;
}
''');
  }

  void test_noLint_untypedCollectionLiteral() async {
    await assertNoDiagnostics(r'''
enum Status { idle, loading, success, error }

void f() {
  var x = [Status.idle, Status.loading];
}
''');
  }

  void test_ternaryExpression() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void f(bool condition) {
  Status s = condition ? Status.idle : Status.loading;
}
''',
      [lint(97, 6), lint(111, 6)],
    );
  }

  void test_nullishCoalescing() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void f(Status? maybeStatus) {
  Status result = maybeStatus ?? Status.idle;
}
''',
      [lint(110, 6)],
    );
  }

  void test_collectionIfElement() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void f(bool condition) {
  var x = <Status>[if (condition) Status.idle];
}
''',
      [lint(106, 6)],
    );
  }

  void test_collectionForElement() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void f() {
  var x = <Status>[for (var i = 0; i < 1; i++) Status.idle];
}
''',
      [lint(105, 6)],
    );
  }

  void test_collectionIfElement_inferredType() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void f(bool condition) {
  List<Status> x = [if (condition) Status.idle];
}
''',
      [lint(107, 6)],
    );
  }

  void test_typedMapLiteral() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void f() {
  var x = <String, Status>{'a': Status.idle};
}
''',
      [lint(90, 6)],
    );
  }

  void test_mapLiteral_inferredType() async {
    await assertDiagnostics(
      r'''
enum Status { idle, loading, success, error }

void f() {
  Map<String, Status> x = {'a': Status.idle};
}
''',
      [lint(90, 6)],
    );
  }
}
