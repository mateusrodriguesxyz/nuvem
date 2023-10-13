import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CKModelMacro.self,
        CKReferenceFieldMacro.self,
    ]
}
