// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:shorthand_lints/src/rules/prefer_shorthand_static.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferShorthandStaticTest);
  });
}

@reflectiveTest
class PreferShorthandStaticTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferShorthandStatic();
    super.setUp();
  }

  // Should lint

  void test_staticConst_typedVariable() async {
    await assertDiagnostics(
      r'''
class AppColors {
  static const AppColors primary = AppColors._(0xFF);
  final int value;
  const AppColors._(this.value);
}

AppColors c = AppColors.primary;
''',
      [lint(141, 9)],
    );
  }

  void test_staticConst_equalityRight() async {
    await assertDiagnostics(
      r'''
class AppColors {
  static const AppColors primary = AppColors._(0xFF);
  static const AppColors accent = AppColors._(0x00);
  final int value;
  const AppColors._(this.value);
}

void f(AppColors c) {
  if (c == AppColors.accent) {}
}
''',
      [lint(213, 9)],
    );
  }

  void test_staticConst_namedArgument() async {
    await assertDiagnostics(
      r'''
class AppColors {
  static const AppColors primary = AppColors._(0xFF);
  final int value;
  const AppColors._(this.value);
}

void paint({required AppColors color}) {}

void f() {
  paint(color: AppColors.primary);
}
''',
      [lint(196, 9)],
    );
  }

  void test_staticConst_returnStatement() async {
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

  // Should NOT lint

  void test_noLint_staticReturningDifferentType() async {
    // Spacing.small is a double, not a Spacing — types don't match.
    await assertNoDiagnostics(r'''
class Spacing {
  static const double small = 8.0;
}

void f() {
  double gap = Spacing.small;
}
''');
  }

  void test_noLint_enumConstant_handledByEnumRule() async {
    // Enum constants should NOT trigger the statics rule.
    await assertNoDiagnostics(r'''
enum Status { idle, loading }

Status s = Status.idle;
''');
  }

  void test_noLint_varWithoutTypeAnnotation() async {
    await assertNoDiagnostics(r'''
class AppColors {
  static const AppColors primary = AppColors._(0xFF);
  final int value;
  const AppColors._(this.value);
}

void f() {
  var c = AppColors.primary;
}
''');
  }

  void test_noLint_instanceMember() async {
    // Instance members should not be flagged — only static members.
    await assertNoDiagnostics(r'''
class Foo {
  int get bar => 42;
}

void f(Foo foo) {
  var x = foo.bar;
}
''');
  }
}
