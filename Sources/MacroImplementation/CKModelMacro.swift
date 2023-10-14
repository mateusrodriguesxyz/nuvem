import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CKModelMacro { }

extension CKModelMacro: MemberMacro {
   
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let structDecl = declaration.as(StructDeclSyntax.self) else { return [] }
        
        let recordName: DeclSyntax
        
        if let argument = node.arguments?.trimmedDescription {
            recordName = "\(raw: argument)"
        } else {
            recordName = "\(literal: structDecl.name.text)"
        }
        
        let recordTypeDecl: DeclSyntax = "public static var recordType: CKRecord.RecordType { \(recordName) }"
        
        let recordDecl: DeclSyntax = "var record: CKRecord!"
        
        let creationDateDecl: DeclSyntax = """
        @CKTimestamp(.creation)
        var creationDate: Date?
        """
        
        let modificationDateDecl: DeclSyntax = """
        @CKTimestamp(.modification)
        var modificationDate: Date?
        """
        
        var initDecls = [DeclSyntax]()
                
        initDecls.append("init() { }")
        
        let properties = structDecl.memberBlock.members.compactMap( { $0.decl.as(VariableDeclSyntax.self) })
            .filter({ $0.bindings.first?.accessorBlock == nil }) ?? []
        
        if !properties.isEmpty {
            
            let identifiers = properties.compactMap({ $0.bindings.first?.pattern.as(IdentifierPatternSyntax.self) })
            let types = properties.compactMap({ $0.bindings.first?.typeAnnotation })
            
            let  memberwiseInitDecl: DeclSyntax = """
        init(\(raw: zip(identifiers, types).map({ "\($0.0.trimmedDescription)\($0.1.trimmedDescription)" }).joined(separator: ", "))) {
        \(raw: identifiers.map({ "self.\($0.trimmedDescription) = \($0.trimmedDescription)" }).joined(separator: "\n"))
        }
        """
            
            initDecls.append(memberwiseInitDecl)
            
        }
        
        return [recordTypeDecl, recordDecl, creationDateDecl, modificationDateDecl] + initDecls
        
        
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
        
        let decl = try ExtensionDeclSyntax(
        #"""
        extension \#(type.trimmed): CKModel { }
        """#
        )
        
        return [decl]
        
    }
    
}

extension CKModelMacro: MemberAttributeMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        
        guard 
            let variable = member.as(VariableDeclSyntax.self),
            variable.bindings.first?.accessorBlock == nil,
            let identifier = variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.trimmedDescription
        else {
            return []
        }
        
        
        if let attribute = variable.attributes.first, attribute.trimmedDescription.contains("@CKReferenceField") == true {
            
            let key: DeclSyntax
            
            if let argument = attribute.as(AttributeSyntax.self)?.arguments?.trimmedDescription {
                key = "\(raw: argument)"
            } else {
                key = "\(literal: identifier)"
            }
            
            if 
                let type = variable.bindings.first?.typeAnnotation?.type.as(OptionalTypeSyntax.self)?.wrappedType,
                type.is(ArrayTypeSyntax.self)
            {
                return ["@CKReferenceFields.Many(\(key))"]
            } else {
                return ["@CKReferenceFields.One(\(key))"]
            }
            
        }
        
        if let attribute = variable.attributes.first, attribute.trimmedDescription.contains("@CKAssetField") == true {
            
            let key: DeclSyntax
            
            if let argument = attribute.as(AttributeSyntax.self)?.arguments?.trimmedDescription {
                key = "\(raw: argument)"
            } else {
                key = "\(literal: identifier)"
            }
            
            return ["@CKFields.Asset(\(key))"]
            
        }
        
        if let attribute = variable.attributes.first, attribute.trimmedDescription.contains("@CKField") == true {
            
            let key: DeclSyntax
            
            if let argument = attribute.as(AttributeSyntax.self)?.arguments?.trimmedDescription {
                key = "\(raw: argument)"
            } else {
                key = "\(literal: identifier)"
            }
            
            return ["@CKFields.Default(\(key))"]
            
        }
        
        if variable.attributes.isEmpty {
            return ["@CKFields.Default(\(literal: identifier))"]
        }
        
        return []
    }
    
}
