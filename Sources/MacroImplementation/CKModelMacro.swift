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
        
        let initDecl1: DeclSyntax = "init() { }"
        
        let properties = declaration.as(StructDeclSyntax.self)?.memberBlock.members.compactMap( { $0.decl.as(VariableDeclSyntax.self) }) ?? []
        
        let identifiers = properties.compactMap({ $0.bindings.first?.pattern.as(IdentifierPatternSyntax.self) })
        let types = properties.compactMap({ $0.bindings.first?.typeAnnotation })
        
        let initDecl2: DeclSyntax = """
        init(\(raw: zip(identifiers, types).map({ "\($0.0.trimmedDescription)\($0.1.trimmedDescription)" }).joined(separator: ", "))) {
        \(raw: identifiers.map({ "self.\($0.trimmedDescription) = \($0.trimmedDescription)" }).joined(separator: "\n"))
        }
        """
        
        return [recordDecl, creationDateDecl, modificationDateDecl, initDecl1, initDecl2]
        
        
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
        if let variable = member.as(VariableDeclSyntax.self), variable.attributes.isEmpty,  let key = variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.trimmedDescription {
            return ["@CKField(\(literal: key))"]
        } else {
            return []
        }
    }
    
}
