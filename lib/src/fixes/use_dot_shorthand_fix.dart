import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Quick fix that replaces a fully-qualified type reference with
/// dot shorthand syntax.
///
/// Handles three cases:
/// - `EnumType.value` → `.value`
/// - `ClassName.staticField` → `.staticField`
/// - `ClassName()` → `.new()` / `ClassName.named()` → `.named()`
class UseDotShorthandFix extends ResolvedCorrectionProducer {
  UseDotShorthandFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind =>
      const FixKind('prefer_dot_shorthand.use_shorthand', DartFixKindPriority.standard, 'Use dot shorthand');

  @override
  FixKind get multiFixKind => const FixKind(
    'prefer_dot_shorthand.use_shorthand.multi',
    DartFixKindPriority.standard,
    'Use dot shorthand everywhere in file',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final coveringNode = this.coveringNode;
    if (coveringNode == null) return;

    final parent = coveringNode.parent;

    // Case 1: PrefixedIdentifier — enum value or static member.
    // Diagnostic is reported on the prefix (SimpleIdentifier).
    // Delete the prefix text; the period stays, producing `.identifier`.
    if (parent is PrefixedIdentifier && coveringNode == parent.prefix) {
      await builder.addDartFileEdit(file, (fileBuilder) {
        fileBuilder.addDeletion(SourceRange(parent.prefix.offset, parent.prefix.length));
      });
      return;
    }

    // Case 2: InstanceCreationExpression — constructor call.
    // Diagnostic is reported on the NamedType node.
    if (parent is ConstructorName && coveringNode is NamedType) {
      final instanceCreation = parent.parent;
      if (instanceCreation is! InstanceCreationExpression) return;

      final namedConstructor = instanceCreation.constructorName.name;

      await builder.addDartFileEdit(file, (fileBuilder) {
        if (namedConstructor != null) {
          // Named: `ClassName.named(args)` → `.named(args)`
          // Delete the ClassName; the existing period + name stay.
          fileBuilder.addDeletion(SourceRange(coveringNode.offset, coveringNode.length));
        } else {
          // Unnamed: `ClassName(args)` → `.new(args)`
          // Replace ClassName with `.new`; `const` keyword is preserved
          // automatically since it precedes the NamedType in the AST.
          fileBuilder.addReplacement(SourceRange(coveringNode.offset, coveringNode.length), (editBuilder) {
            editBuilder.write('.new');
          });
        }
      });
      return;
    }
  }
}
