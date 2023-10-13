import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CKModelMacro { }

extension CKModelMacro: MemberMacro {
   
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        
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
        
        let initDecl1: DeclSyntax = "init() { }"
        
        initDecls.append(initDecl1)
        
        let properties = declaration.as(StructDeclSyntax.self)?.memberBlock.members.compactMap( { $0.decl.as(VariableDeclSyntax.self) })
            .filter({ $0.bindings.first?.accessorBlock == nil }) ?? []
        
        if !properties.isEmpty {
            
            let identifiers = properties.compactMap({ $0.bindings.first?.pattern.as(IdentifierPatternSyntax.self) })
            let types = properties.compactMap({ $0.bindings.first?.typeAnnotation })
            
            let initDecl2: DeclSyntax = """
        init(\(raw: zip(identifiers, types).map({ "\($0.0.trimmedDescription)\($0.1.trimmedDescription)" }).joined(separator: ", "))) {
        \(raw: identifiers.map({ "self.\($0.trimmedDescription) = \($0.trimmedDescription)" }).joined(separator: "\n"))
        }
        """
            
            initDecls.append(initDecl2)
            
        }
        
        return [recordDecl, creationDateDecl, modificationDateDecl] + initDecls
        
        
    }
    
    
}

extension CKModelMacro: ExtensionMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        
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
            
            if let type = variable.bindings.first?.typeAnnotation?.type.as(OptionalTypeSyntax.self)?.wrappedType, type.is(ArrayTypeSyntax.self) {
                return ["@CKReferenceField.Many(\(key))"]
            } else {
                return ["@CKReferenceField.One(\(key))"]
            }
            
        }
        
        if variable.attributes.isEmpty {
            return ["@CKField(\(literal: identifier))"]
        }
        
        return []
    }
    
}
