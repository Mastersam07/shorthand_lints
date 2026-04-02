// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:shorthand_lints/src/rules/avoid_nested_shorthands.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidNestedShorthandsTest);
  });
}

@reflectiveTest
class AvoidNestedShorthandsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedShorthands();
    super.setUp();
  }

  // Should lint

  void test_nestedShorthand_constructorArg() async {
    // `.new(...)` containing `.new(...)` as argument.
    await assertDiagnostics(
      r'''
class Inner {
  final String value;
  Inner(this.value);
}

class Outer {
  final Inner inner;
  Outer(this.inner);
}

Outer o = .new(.new('val'));
''',
      [lint(134, 11)],
    );
  }

  void test_nestedShorthand_namedArg() async {
    await assertDiagnostics(
      r'''
class Inner {
  final String value;
  Inner(this.value);
}

class Wrapper {
  final Inner inner;
  Wrapper({required this.inner});
}

Wrapper w = .new(inner: .new('val'));
''',
      [lint(158, 11)],
    );
  }

  void test_nestedShorthand_multipleArgs() async {
    await assertDiagnostics(
      r'''
class A {
  final String v;
  A(this.v);
}

class B {
  final A a1;
  final A a2;
  B(this.a1, this.a2);
}

B b = .new(.new('x'), .new('y'));
''',
      [lint(119, 9), lint(130, 9)],
    );
  }

  // Should NOT lint

  void test_noLint_fullyQualifiedNesting() async {
    // Fully-qualified calls are not shorthands — no readability concern.
    await assertNoDiagnostics(r'''
class Inner {
  final String value;
  Inner(this.value);
}

class Outer {
  final Inner inner;
  Outer(this.inner);
}

void f() {
  var o = Outer(Inner('val'));
}
''');
  }

  void test_noLint_shorthandWithFullyQualifiedArg() async {
    // Outer is shorthand, but inner is fully qualified — this is fine.
    await assertNoDiagnostics(r'''
class Inner {
  final String value;
  Inner(this.value);
}

class Outer {
  final Inner inner;
  Outer(this.inner);
}

Outer o = .new(Inner('val'));
''');
  }

  void test_noLint_shorthandWithPrimitiveArg() async {
    // Shorthand with a non-shorthand argument — no nesting.
    await assertNoDiagnostics(r'''
class MyClass {
  final String value;
  MyClass(this.value);
}

MyClass m = .new('hello');
''');
  }

  void test_nestedShorthand_staticMethodInvocation() async {
    // Outer is a DotShorthandInvocation (static method), inner is shorthand
    await assertDiagnostics(
      r'''
class Inner {
  final String value;
  Inner(this.value);
}

class Outer {
  final Inner inner;
  Outer(this.inner);
  static Outer create(Inner inner) => Outer(inner);
}

Outer o = .create(.new('val'));
''',
      [lint(189, 11)],
    );
  }

  void test_nestedShorthand_defaultMaxDepth_flagsAtDepth1() async {
    // max_depth: 0 (default) — flag any nesting
    await assertDiagnostics(
      r'''
class Inner {
  final String value;
  Inner(this.value);
}

class Outer {
  final Inner inner;
  Outer(this.inner);
}

Outer o = .new(.new('val'));
''',
      [lint(134, 11)],
    );
  }

  void test_noLint_maxDepth1_allowsDepth1() async {
    // max_depth: 1 — allow 1 level of nesting
    rule.options = {'max_depth': 1};
    await assertNoDiagnostics(r'''
class Inner {
  final String value;
  Inner(this.value);
}

class Outer {
  final Inner inner;
  Outer(this.inner);
}

Outer o = .new(.new('val'));
''');
  }

  void test_nestedShorthand_maxDepth1_flagsAtDepth2() async {
    // max_depth: 1 — allow 1 level, flag at 2+
    rule.options = {'max_depth': 1};
    await assertDiagnostics(
      r'''
class A {
  final String v;
  A(this.v);
}

class B {
  final A a;
  B(this.a);
}

class C {
  final B b;
  C(this.b);
}

C c = .new(.new(.new('val')));
''',
      [lint(131, 11)],
    );
  }

  void test_noLint_fullyQualifiedWithShorthandArg() async {
    // The parent call is NOT a shorthand (it's fully qualified),
    // so nested shorthand in its args is fine — only the combo hurts.
    await assertNoDiagnostics(r'''
class Inner {
  final String value;
  Inner(this.value);
}

class Outer {
  final Inner inner;
  Outer(this.inner);
}

void f() {
  Outer o = Outer(.new('val'));
}
''');
  }
}
