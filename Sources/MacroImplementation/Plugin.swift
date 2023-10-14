import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CKModelMacro.self,
        CKFieldMacro.self,
        CKAssetFieldMacro.self,
        CKReferenceFieldMacro.self,
    ]
}
