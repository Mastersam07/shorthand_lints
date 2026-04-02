# shorthand_lints

A Dart analyzer plugin that provides lint rules to encourage **dot shorthand syntax** (Dart 3.10+).

Built on the [new first-party analyzer plugin system](https://dart.dev/tools/analyzer-plugins) — diagnostics appear directly in your IDE and `dart analyze` output with no extra commands needed.

## Rules

| Rule | Description |
|---|---|
| `prefer_dot_shorthand_for_enums` | Flags `EnumType.value` where `.value` would work |
| `prefer_dot_shorthand_for_constructors` | Flags `ClassName()` / `ClassName.named()` where `.new()` / `.named()` would work |
| `prefer_dot_shorthand_for_statics` | Flags `ClassName.staticMember` where `.staticMember` would work |
| `prefer_returning_shorthands` | Flags return values that could use dot shorthand to match the return type |
| `avoid_nested_shorthands` | Warns when shorthand arguments contain other shorthands (readability guard) |

The first four rules include a **quick fix** so you can apply the shorthand with one click in your IDE (or via `dart fix`). `avoid_nested_shorthands` has no auto-fix since expanding nested shorthands is context-dependent.

## Requirements

- **Dart SDK** ≥ 3.10.0 (ships with Flutter 3.38+)

## Setup

### 1. Add the dependency

```yaml
# pubspec.yaml
dev_dependencies:
  shorthand_lints:
    git:
      url: https://github.com/mastersam07/shorthand_lints
      ref: dev
```

### 2. Enable in analysis_options.yaml

```yaml
# analysis_options.yaml
plugins:
  shorthand_lints: ^0.1.0

  diagnostics:
    prefer_dot_shorthand_for_enums: true
    prefer_dot_shorthand_for_constructors: true
    prefer_dot_shorthand_for_statics: true
    prefer_returning_shorthands: true
    avoid_nested_shorthands: true
```

### 3. Restart the analysis server

In VS Code: `Cmd+Shift+P` → "Dart: Restart Analysis Server"

## Examples

### Enums

```dart
// Before (flagged) ⛔
Status status = Status.loading;
if (status == Status.success) { ... }

// After (preferred) ✅
Status status = .loading;
if (status == .success) { ... }
```

### Constructors

```dart
// Before (flagged) ⛔
final ScrollController controller = ScrollController();
final Point origin = Point.origin();

// After (preferred) ✅
final ScrollController controller = .new();
final Point origin = .origin();
```

### Static members

```dart
// Before (flagged) ⛔
AppColors color = AppColors.primary;

// After (preferred) ✅
AppColors color = .primary;
```

### Return statements

```dart
// Before (flagged) ⛔
Status getStatus() => Status.success;
Point buildPoint() { return Point.origin(); }

// After (preferred) ✅
Status getStatus() => .success;
Point buildPoint() { return .origin(); }

// Also works with async — unwraps Future<T>:
Future<Status> fetch() async => .loading; // ✅
```

### Nested shorthands (readability guard)

```dart
// Flagged ⛔ — inner arguments are also shorthands
final Another a = .new(.new(version: .new('val')));
//                     ^^^^ flagged  ^^^^ flagged

// Preferred ✅ — expand inner levels for clarity
final Another a = .new(Some(version: SomeClass('val')));
```

## When the rules DON'T fire

The rules are conservative and only flag code where shorthand is guaranteed to compile:

- **No type annotation**: `var x = Status.loading;` — no context type, shorthand won't work.
- **Type mismatch**: `double gap = Spacing.small;` — `Spacing.small` is a `double`, not `Spacing`.
- **Dynamic context**: `dynamic d = Status.loading;` — shorthand needs a concrete type.
- **No return type annotation**: `getStatus() => Status.loading;` — inferred return types are not flagged.
- **Shorthand on left of `==`**: This is a Dart compile error, not a lint concern.

## Suppressing diagnostics

```dart
// ignore: prefer_dot_shorthand/prefer_dot_shorthand_for_enums
Status status = Status.loading;
```

Or disable a rule project-wide:

```yaml
plugins:
  shorthand_lints: ^0.1.0
  diagnostics:
    prefer_dot_shorthand_for_enums: false
```

## Contributing

PRs welcome! Some areas to improve:

- **More context detection**: collection literals without explicit type args, cascade targets, spread elements.
- **Configurable severity**: allow teams to choose between `info` and `warning`.
- **Configurable nesting depth**: allow one level of nesting but flag two+.

## License

MIT
