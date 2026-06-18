import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct NuvemMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CKModelMacro.self,
        CKFieldMacro.self,
        CKAssetFieldMacro.self,
        CKAssetListFieldMacro.self,
        CKReferenceFieldMacro.self,
        CKReferenceListFieldMacro.self,
    ]
}
