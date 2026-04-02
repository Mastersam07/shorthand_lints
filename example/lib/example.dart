// ignore_for_file: unused_local_variable, unused_element

/// Example file demonstrating cases flagged by prefer_dot_shorthand.
///
/// Run `dart analyze` in this directory to see the lint diagnostics.

/// Enums

enum Status { idle, loading, success, error }

enum Alignment { topLeft, topRight, bottomLeft, bottomRight, center }

void enumExamples() {
  // LINT: prefer_dot_shorthand_for_enums
  // Fix: Status status = .loading;
  Status status = Status.loading;

  // LINT: prefer_dot_shorthand_for_enums (right side of ==)
  // Fix: if (status == .success)
  if (status == Status.success) {
    print('done');
  }

  // LINT: prefer_dot_shorthand_for_enums (switch case)
  // Fix: case .idle:
  switch (status) {
    case Status.idle:
      break;
    case Status.loading:
      break;
    case Status.success:
      break;
    case Status.error:
      break;
  }

  // LINT: prefer_dot_shorthand_for_enums (typed list literal)
  // Fix: <Status>[.idle, .loading]
  final states = <Status>[Status.idle, Status.loading];

  // NO LINT: no explicit type context (var with no annotation)
  var x = Status.loading;
}

Status getStatus() {
  // LINT: prefer_dot_shorthand_for_enums (return statement)
  // Fix: return .success;
  return Status.success;
}

/// Constructors

class Point {
  final double x, y;
  const Point(this.x, this.y);
  const Point.origin() : x = 0, y = 0;
}

class Controller {
  Controller();
  Controller.withDelay(Duration delay);
}

void constructorExamples() {
  // LINT: prefer_dot_shorthand_for_constructors (unnamed)
  // Fix: final Point p = .new(1.0, 2.0);
  final Point p = Point(1.0, 2.0);

  // LINT: prefer_dot_shorthand_for_constructors (named)
  // Fix: final Point origin = .origin();
  final Point origin = Point.origin();

  // LINT: prefer_dot_shorthand_for_constructors
  // Fix: final Controller c = .new();
  final Controller c = Controller();

  // NO LINT: no explicit type context
  var p2 = Point(3.0, 4.0);
}

Point buildPoint() {
  // LINT: prefer_dot_shorthand_for_constructors (return)
  // Fix: return .origin();
  return Point.origin();
}

/// Static members

class AppColors {
  static const AppColors primary = AppColors._(0xFF0000);
  static const AppColors secondary = AppColors._(0x00FF00);
  static const AppColors accent = AppColors._(0x0000FF);

  final int value;
  const AppColors._(this.value);
}

class Spacing {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  // Note: these are `double`, not `Spacing`, so the rule won't flag them.
  // The rule only fires when the static member's type matches the class.
}

void staticExamples() {
  // LINT: prefer_dot_shorthand_for_statics
  // Fix: AppColors color = .primary;
  AppColors color = AppColors.primary;

  // LINT: prefer_dot_shorthand_for_statics (== comparison)
  // Fix: if (color == .accent)
  if (color == AppColors.accent) {
    print('accent');
  }

  // NO LINT: Spacing.small is double, not Spacing — types don't match
  double gap = Spacing.small;
}

/// Named arguments

void renderBox({required Alignment alignment, required AppColors color}) {}

void namedArgExamples() {
  // LINT: both arguments can use shorthand
  renderBox(alignment: Alignment.center, color: AppColors.primary);
  // Fix:
  // renderBox(
  //   alignment: .center,
  //   color: .primary,
  // );
}

/// Default parameter values

// LINT: prefer_dot_shorthand_for_enums
// Fix: void fetch({Status initial = .idle}) {}
void fetch({Status initial = Status.idle}) {}

/// Mixed: no false positives

void noLintCases() {
  // NO LINT: var declaration without type annotation
  var s = Status.loading;

  // NO LINT: shorthand on the LEFT of == is invalid Dart
  // (this is a compile error, not a lint concern)

  // NO LINT: dynamic context
  dynamic d = Status.loading;
}

/// Returning shorthands

Status getStatusBad() {
  // LINT: prefer_returning_shorthands
  // Fix: return .success;
  return Status.success;
}

Status getStatusBadArrow() =>
    // LINT: prefer_returning_shorthands (expression body)
    // Fix: => .error;
    Status.error;

Point buildPointBad() {
  // LINT: prefer_returning_shorthands (constructor)
  // Fix: return .origin();
  return Point.origin();
}

AppColors getColorBad() {
  // LINT: prefer_returning_shorthands (static const)
  // Fix: return .accent;
  return AppColors.accent;
}

Future<Status> getAsyncStatus() async {
  // LINT: prefer_returning_shorthands (async function — unwraps Future<T>)
  // Fix: return .loading;
  return Status.loading;
}

// NO LINT: no explicit return type annotation
getStatusInferred() {
  return Status.loading;
}

/// Nested shorthands

class SomeClass {
  final String value;
  const SomeClass(this.value);
}

class Some {
  final SomeClass version;
  const Some({required this.version});
}

class Another {
  final Some some;
  Another(this.some);
}

void nestedShorthandExamples() {
  // LINT: avoid_nested_shorthands (inner `.new(version: .new('val'))`)
  // The outermost `.new(...)` is fine, but its arguments should not
  // also be shorthands — it becomes unreadable.
  //
  // Assuming these are already using shorthand syntax:
  //   final Another a = .new(.new(version: .new('val')));
  //
  // GOOD — expand inner levels:
  //   final Another a = .new(Some(version: SomeClass('val')));

  // Note: avoid_nested_shorthands only fires when the PARENT call
  // is itself a dot shorthand (starts with `.`). The rule checks
  // arguments of shorthand invocations for other shorthands.

  // Direct fully-qualified nesting is NOT flagged by this rule
  // (it's fine — there's no readability issue):
  final Another a = Another(Some(version: SomeClass('val')));
}
