import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:shorthand_lints/src/rules/prefer_shorthand_enum.dart';
import 'package:shorthand_lints/src/rules/prefer_shorthand_constructor.dart';
import 'package:shorthand_lints/src/rules/prefer_shorthand_static.dart';
import 'package:shorthand_lints/src/rules/avoid_nested_shorthands.dart';
import 'package:shorthand_lints/src/rules/prefer_returning_shorthands.dart';
import 'package:shorthand_lints/src/fixes/use_dot_shorthand_fix.dart';

/// Top-level plugin instance required by the analyzer plugin system.
final plugin = PreferDotShorthandPlugin();

/// An analyzer plugin that provides lint rules encouraging
/// dot shorthand syntax where the type prefix is redundant.
///
/// Rules provided:
/// - `prefer_dot_shorthand_for_enums`
/// - `prefer_dot_shorthand_for_constructors`
/// - `prefer_dot_shorthand_for_statics`
/// - `avoid_nested_shorthands`
/// - `prefer_returning_shorthands`
class PreferDotShorthandPlugin extends Plugin {
  @override
  String get name => 'prefer_dot_shorthand';

  @override
  void register(PluginRegistry registry) {
    registry.registerLintRule(PreferShorthandEnum());
    registry.registerLintRule(PreferShorthandConstructor());
    registry.registerLintRule(PreferShorthandStatic());
    registry.registerLintRule(PreferReturningShorthands());
    registry.registerLintRule(AvoidNestedShorthands());

    registry.registerFixForRule(PreferShorthandEnum.code, UseDotShorthandFix.new);
    registry.registerFixForRule(PreferShorthandConstructor.code, UseDotShorthandFix.new);
    registry.registerFixForRule(PreferShorthandStatic.code, UseDotShorthandFix.new);
    registry.registerFixForRule(PreferReturningShorthands.code, UseDotShorthandFix.new);
  }
}
