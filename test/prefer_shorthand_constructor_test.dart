// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:shorthand_lints/src/rules/prefer_shorthand_constructor.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferShorthandConstructorTest);
  });
}

@reflectiveTest
class PreferShorthandConstructorTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferShorthandConstructor();
    super.setUp();
  }

  // Should lint

  void test_unnamedConstructor_typedVariable() async {
    await assertDiagnostics(
      r'''
class Point {
  final double x, y;
  Point(this.x, this.y);
}

Point p = Point(1.0, 2.0);
''',
      [lint(73, 5)],
    );
  }

  void test_namedConstructor_typedVariable() async {
    await assertDiagnostics(
      r'''
class Point {
  final double x, y;
  Point(this.x, this.y);
  Point.origin() : x = 0, y = 0;
}

Point p = Point.origin();
''',
      [lint(106, 5)],
    );
  }

  void test_constConstructor_typedVariable() async {
    await assertDiagnostics(
      r'''
class Point {
  final double x, y;
  const Point(this.x, this.y);
}

Point p = const Point(1.0, 2.0);
''',
      [lint(85, 5)],
    );
  }

  void test_returnStatement_unnamed() async {
    await assertDiagnostics(
      r'''
class Point {
  final double x, y;
  Point(this.x, this.y);
}

Point f() {
  return Point(1.0, 2.0);
}
''',
      [lint(84, 5)],
    );
  }

  void test_returnStatement_named() async {
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

  void test_namedArgument() async {
    await assertDiagnostics(
      r'''
class Offset {
  final double dx, dy;
  Offset(this.dx, this.dy);
}

void render({required Offset offset}) {}

void f() {
  render(offset: Offset(10, 20));
}
''',
      [lint(139, 6)],
    );
  }

  void test_positionalArgument() async {
    await assertDiagnostics(
      r'''
class Offset {
  final double dx, dy;
  Offset(this.dx, this.dy);
}

void render(Offset offset) {}

void f() {
  render(Offset(10, 20));
}
''',
      [lint(120, 6)],
    );
  }

  void test_constructorFieldInitializer() async {
    await assertDiagnostics(
      r'''
class Offset {
  final double dx, dy;
  Offset(this.dx, this.dy);
}

class Widget {
  final Offset offset;
  Widget() : offset = Offset(0, 0);
}
''',
      [lint(129, 6)],
    );
  }

  void test_typedListLiteral() async {
    await assertDiagnostics(
      r'''
class Point {
  final double x, y;
  Point(this.x, this.y);
}

void f() {
  var x = <Point>[Point(0, 0), Point(1, 1)];
}
''',
      [lint(92, 5), lint(105, 5)],
    );
  }

  // Should NOT lint

  void test_noLint_varWithoutTypeAnnotation() async {
    await assertNoDiagnostics(r'''
class Point {
  final double x, y;
  Point(this.x, this.y);
}

void f() {
  var p = Point(1.0, 2.0);
}
''');
  }

  void test_noLint_finalWithoutTypeAnnotation() async {
    await assertNoDiagnostics(r'''
class Point {
  final double x, y;
  Point(this.x, this.y);
}

void f() {
  final p = Point(1.0, 2.0);
}
''');
  }

  void test_noLint_untypedCollectionLiteral() async {
    await assertNoDiagnostics(r'''
class Point {
  final double x, y;
  Point(this.x, this.y);
}

void f() {
  var x = [Point(0, 0), Point(1, 1)];
}
''');
  }

  void test_noLint_subtypeInVariable() async {
    // Animal a = Dog('Rex') — Dog != Animal, shorthand would call Animal(), not Dog()
    await assertNoDiagnostics(r'''
abstract class Animal {
  String get name;
}

class Dog extends Animal {
  @override
  final String name;
  Dog(this.name);
}

void f() {
  Animal a = Dog('Rex');
}
''');
  }

  void test_noLint_subtypeNamedConstructor() async {
    await assertNoDiagnostics(r'''
abstract class Animal {
  String get name;
}

class Dog extends Animal {
  @override
  final String name;
  Dog(this.name);
  Dog.buddy() : name = 'Buddy';
}

void f() {
  Animal a = Dog.buddy();
}
''');
  }

  void test_noLint_subtypeInReturnStatement() async {
    await assertNoDiagnostics(r'''
abstract class Animal {
  String get name;
}

class Dog extends Animal {
  @override
  final String name;
  Dog(this.name);
}

Animal f() {
  return Dog('Rex');
}
''');
  }

  void test_noLint_subtypeInNamedArgument() async {
    await assertNoDiagnostics(r'''
abstract class Animal {
  String get name;
}

class Dog extends Animal {
  @override
  final String name;
  Dog(this.name);
}

void render({required Animal animal}) {}

void f() {
  render(animal: Dog('Rex'));
}
''');
  }

  void test_methodReturn_unnamed() async {
    await assertDiagnostics(
      r'''
class Point {
  final double x, y;
  Point(this.x, this.y);
}

class Factory {
  Point build() {
    return Point(1, 2);
  }
}
''',
      [lint(108, 5)],
    );
  }

  void test_noLint_subtypeInPositionalArgument() async {
    await assertNoDiagnostics(r'''
abstract class Animal {
  String get name;
}

class Dog extends Animal {
  @override
  final String name;
  Dog(this.name);
}

void render(Animal animal) {}

void f() {
  render(Dog('Rex'));
}
''');
  }

  void test_cascadeTarget_typedVariable() async {
    await assertDiagnostics(
      r'''
class Point {
  double x = 0, y = 0;
  Point(this.x, this.y);
}

void f() {
  Point p = Point(1, 2)..x = 3;
}
''',
      [lint(88, 5)],
    );
  }
}
