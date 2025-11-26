import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct NuvemMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CKModelMacro.self,
    ]
}
