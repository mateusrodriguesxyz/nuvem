import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct FieldAttributeInfo {
    let key: String?
}

struct ReferenceFieldAttributeInfo {
    let key: String?
    let action: String?
}

private func extractKey(from node: AttributeSyntax) -> String? {
    node.arguments?.as(LabeledExprListSyntax.self)?
        .first(where: { $0.label == nil })?
        .expression.as(StringLiteralExprSyntax.self)?
        .representedLiteralValue
}

private func fieldAttributeInfo(from node: AttributeSyntax) -> FieldAttributeInfo {
    FieldAttributeInfo(key: extractKey(from: node))
}

private func referenceFieldAttributeInfo(from node: AttributeSyntax) -> ReferenceFieldAttributeInfo {
    ReferenceFieldAttributeInfo(
        key: extractKey(from: node),
        action: node.arguments?.as(LabeledExprListSyntax.self)?
            .first(where: { $0.label?.text == "action" })?
            .expression.trimmedDescription
    )
}

/// Collects labeled argument strings from an attribute syntax node, optionally excluding certain labels.
/// Each returned string is in the form "label: value".
private func labeledArgs(from node: AttributeSyntax, excluding: Set<String> = []) -> [String] {
    let labelExprList = node.arguments?.as(LabeledExprListSyntax.self) ?? []
    var result: [String] = []
    for arg in labelExprList {
        guard let label = arg.label?.text else { continue }
        if excluding.contains(label) { continue }
        result.append("\(label): \(arg.expression.trimmedDescription)")
    }
    return result
}

public enum CKModelMacro { }

extension CKModelMacro: MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let structDecl = declaration.as(StructDeclSyntax.self) else { return [] }
        
        let recordName: DeclSyntax
        
        let observableTypealiasDecl: DeclSyntax = "typealias Observable = CKObservable<\(structDecl.name.trimmed)>"
        
        if let argument = node.arguments?.trimmedDescription, !argument.isEmpty {
            recordName = "\(raw: argument)"
        } else {
            recordName = "\(literal: structDecl.name.text)"
        }
        
        let recordTypeDecl: DeclSyntax = "public static let recordType: CKRecord.RecordType = \(recordName)"
        
        let recordDecl: DeclSyntax = "var record: CKRecord! = CKRecord(recordType: \(recordName))"
        
        let creationDateDecl: DeclSyntax = """
        @CKTimestamp(.creation)
        var creationDate: Date?
        """
        
        let modificationDateDecl: DeclSyntax = """
        @CKTimestamp(.modification)
        var modificationDate: Date?
        """
        
        return [
            observableTypealiasDecl,
            creationDateDecl,
            modificationDateDecl,
            recordTypeDecl,
            recordDecl
        ]
        
    }
    
}

extension CKModelMacro: ExtensionMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        guard let structDecl = declaration.as(StructDeclSyntax.self) else { return [] }
        
        let hasExistingEmptyInit = structDecl.memberBlock.members.contains { member in
            guard let initDecl = member.decl.as(InitializerDeclSyntax.self) else { return false }
            return initDecl.signature.parameterClause.parameters.isEmpty
        }
        
        var fieldIds: [String] = []
        var fieldTypes: [String] = []
        var fieldAttrs: [AttributeSyntax] = []
        
        for member in structDecl.memberBlock.members {
            guard
                let variable = member.decl.as(VariableDeclSyntax.self),
                let binding = variable.bindings.first,
                let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                let propertyType = binding.typeAnnotation?.type.trimmedDescription
            else {
                continue
            }
            
            if let attributeSyntax = fieldMacroAttribute(variable) {
                fieldIds.append(identifier)
                fieldTypes.append(propertyType)
                fieldAttrs.append(attributeSyntax)
            } else {
                // Warn for non-field, non-optional stored properties without default values.
                guard !variable.modifiers.contains(where: { $0.name.text == "static" }) else { continue }
                for binding in variable.bindings {
                    if binding.accessorBlock != nil { continue }
                    if binding.initializer != nil { continue }
                    guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                          let typeAnnotation = binding.typeAnnotation
                    else { continue }
                    
                    if !isOptionalType(typeAnnotation.type.trimmedDescription) {
                        context.diagnose(Diagnostic(
                            node: Syntax(pattern),
                            message: NonOptionalPropertyWarning(propertyName: pattern.identifier.text)
                        ))
                    }
                }
            }
        }
        
        // Check 2: When NO field properties exist, or ALL of them have optional
        // types, Swift auto-synthesizes init(). This happens because each init
        // accessor's implicit newValue parameter defaults to nil for optional
        // types. In this case we must NOT generate init() in the extension
        // to avoid "Invalid redeclaration of synthesized 'init()'".
        let willAutoSynthesizeInit = fieldIds.isEmpty
            || fieldIds.indices.allSatisfy { isOptionalType(fieldTypes[$0]) }
        
        if hasExistingEmptyInit || willAutoSynthesizeInit {
            // Swift provides init() (either user-written or auto-synthesized).
            // Extension just needs the conformance declaration.
            return [try ExtensionDeclSyntax("extension \(type.trimmed): CKModel { }")]
        }
        
        // Generate init() with storage property initialization.
        var initStatements: [String] = []
        for (index, attrSyntax) in fieldAttrs.enumerated() {
            let attrName = attrSyntax.attributeName.trimmedDescription
            let identifier = fieldIds[index]
            let propertyType = fieldTypes[index]
            
            // Determine storage type and generic parameter
            let storageType: String
            let genericParam: String
            switch attrName {
            case "CKField":
                storageType = "CKField"
                genericParam = propertyType
            case "CKAssetField":
                storageType = "CKAssetField"
                genericParam = propertyType
            case "CKAssetListField":
                storageType = "CKAssetListField"
                genericParam = listFieldGenericType(from: propertyType)
            case "CKReferenceField":
                storageType = "CKReferenceField"
                genericParam = referenceFieldGenericType(from: propertyType)
            case "CKReferenceListField":
                storageType = "CKReferenceListField"
                genericParam = listFieldGenericType(from: propertyType)
            default:
                continue
            }
            
            let isReference = attrName == "CKReferenceField" || attrName == "CKReferenceListField"
            
            if isReference {
                let info = referenceFieldAttributeInfo(from: attrSyntax)
                let keyLiteral = "\"\(info.key ?? identifier)\""
                let extraArgs = labeledArgs(from: attrSyntax, excluding: ["action"])
                let actionValue = info.action ?? ".none"
                let allArgs = ([keyLiteral] + extraArgs + ["action: \(actionValue)"]).joined(separator: ", ")
                initStatements.append("self._\(identifier) = \(storageType)<\(genericParam)>(\(allArgs))")
            } else {
                let info = fieldAttributeInfo(from: attrSyntax)
                let keyLiteral = "\"\(info.key ?? identifier)\""
                let extraArgs = labeledArgs(from: attrSyntax)
                let allArgs = ([keyLiteral] + extraArgs).joined(separator: ", ")
                initStatements.append("self._\(identifier) = \(storageType)<\(genericParam)>(\(allArgs))")
            }
        }
        
        let initDecl: DeclSyntax = """
            init() {
            \(raw: initStatements.joined(separator: "\n"))
            }
            """
        
        let decl = try ExtensionDeclSyntax("""
            extension \(type.trimmed): CKModel {
            \(initDecl)
            }
            """)
        
        return [decl]
        
    }
    
}
