import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CKReferenceListFieldMacro: AccessorMacro, PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let property = declaration.as(VariableDeclSyntax.self),
            let identifier = property.identifier,
            let type = property.type?.as(ArrayTypeSyntax.self)
        else {
            return []
        }

        let storageDecl: DeclSyntax = "var _\(identifier): CKReferenceListField<\(type.element)>"

        let projectedDecl: DeclSyntax = """
        var $\(identifier): CKReferenceListField<\(type.element)> { _\(identifier).projectedValue }
        """

        return [storageDecl, projectedDecl]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard
            let property = declaration.as(VariableDeclSyntax.self),
            let identifier = property.identifier,
            let type = property.type?.as(ArrayTypeSyntax.self)
        else {
            return []
        }

        let info = referenceFieldAttributeInfo(from: node)
        
        let key = info.key ?? identifier.identifier.text
        let action = info.action ?? ".none"

        let getAccessor: AccessorDeclSyntax = """
        get {
            _\(identifier).wrappedValue
        }
        """

        let setAccessor: AccessorDeclSyntax = """
        set {
            _\(identifier).wrappedValue = newValue
        }
        """

        let initAccessor: AccessorDeclSyntax = """
        @storageRestrictions(initializes: _\(identifier))
        init {
            self._\(identifier) = CKReferenceListField<\(type.element)>(wrappedValue: newValue, \(literal: key), action: \(raw: action))
        }
        """

        return [getAccessor, setAccessor, initAccessor]
    }
}
