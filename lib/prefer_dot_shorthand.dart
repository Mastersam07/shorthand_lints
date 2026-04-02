/// Analyzer plugin providing lint rules for Dart dot shorthand syntax.
///
/// This plugin offers five opt-in lint rules:
///
/// - `prefer_dot_shorthand_for_enums`: Flags redundant enum type prefixes.
/// - `prefer_dot_shorthand_for_constructors`: Flags redundant constructor prefixes.
/// - `prefer_dot_shorthand_for_statics`: Flags redundant static member prefixes.
/// - `avoid_nested_shorthands`: Flags nested dot shorthands that hurt readability.
/// - `prefer_returning_shorthands`: Flags return values that could use shorthand.
///
/// ## Usage
///
/// Add to your `analysis_options.yaml`:
///
/// ```yaml
/// plugins:
///   prefer_dot_shorthand: ^0.1.0
///
///   diagnostics:
///     prefer_dot_shorthand_for_enums: true
///     prefer_dot_shorthand_for_constructors: true
///     prefer_dot_shorthand_for_statics: true
///     avoid_nested_shorthands: true
///     prefer_returning_shorthands: true
/// ```
library;

export 'src/rules/prefer_shorthand_enum.dart';
export 'src/rules/prefer_shorthand_constructor.dart';
export 'src/rules/prefer_shorthand_static.dart';
export 'src/rules/avoid_nested_shorthands.dart';
export 'src/rules/prefer_returning_shorthands.dart';
