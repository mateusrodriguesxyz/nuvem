import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public enum CKModelMacro: MemberMacro, ExtensionMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let structDecl = declaration.as(StructDeclSyntax.self) else { return [] }
        
        let recordName = if let argument = node.arguments?.trimmedDescription, !argument.isEmpty {
            argument
        } else {
            structDecl.name.text
        }
        
        let recordTypeDecl: DeclSyntax = "public static let recordType: CKRecord.RecordType = \(literal: recordName)"
        
        let recordDecl: DeclSyntax = "var record: CKRecord! = CKRecord(recordType: \(literal: recordName))"
        
        let creationDateDecl: DeclSyntax = """
        @CKTimestamp(.creation)
        var creationDate: Date?
        """
        
        let modificationDateDecl: DeclSyntax = """
        @CKTimestamp(.modification)
        var modificationDate: Date?
        """
        
        return [
            creationDateDecl,
            modificationDateDecl,
            recordTypeDecl,
            recordDecl
        ]
        
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        guard declaration.is(StructDeclSyntax.self) else { return [] }
        
        var fields: [FieldPropertyInfo] = []
        
        for member in declaration.memberBlock.members {
            guard
                let variable = member.decl.as(VariableDeclSyntax.self),
                let binding = variable.bindings.first,
                let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
            else {
                continue
            }
            
            if let attribute = fieldMacroAttribute(variable) {
                fields.append(.init(name: identifier, attribute: attribute))
            } else {
                guard !variable.modifiers.contains(where: { $0.name.text == "static" }) else { continue }
                for binding in variable.bindings {
                    if binding.accessorBlock != nil { continue }
                    if binding.initializer != nil { continue }
                    guard
                        let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
                        let type = binding.typeAnnotation?.type
                    else {
                        continue
                    }
                    if !type.is(OptionalTypeSyntax.self) {
                        context.diagnose(
                            Diagnostic(
                                node: Syntax(variable),
                                message: MacroExpansionErrorMessage(
                                    "@CKModel requires non-optional property '\(identifier.text)' to have a default value"
                                ),
                            )
                        )
                    }
                }
            }
        }
        
        var inits: [DeclSyntax] = []
        
        for field in fields {
            if field.isReference {
                let info = referenceFieldAttributeInfo(from: field.attribute)
                let key = info.key ?? field.name.text
                let action = info.action ?? ".none"
                inits.append("self._\(field.name) = .init(\(literal: key), action: \(raw: action))")
            } else {
                let info = fieldAttributeInfo(from: field.attribute)
                let key = info.key ?? field.name.text
                inits.append("self._\(field.name) = .init(\(literal: key))")
            }
        }
        
        let initDecl: DeclSyntax = """
            init(record: CKRecord) {
                \(CodeBlockItemListSyntax { inits })
                self.record = record
                bindRecordToFields()
            }
            """
        
        let decl = try ExtensionDeclSyntax("""
            extension \(type): CKModel {
            \(initDecl)
            }
            """)
        
        return [decl]
        
    }
    
}
