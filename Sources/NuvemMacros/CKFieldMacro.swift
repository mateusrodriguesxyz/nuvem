import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CKFieldMacro: AccessorMacro, PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let property = declaration.as(VariableDeclSyntax.self),
            let identifier = property.identifier,
            let type = property.type
        else {
            return []
        }

        let storageDecl: DeclSyntax = "var _\(identifier): CKField<\(type)>"

        let projectedDecl: DeclSyntax = """
        var $\(identifier): CKField<\(type)> { _\(identifier).projectedValue }
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
            let type = property.type
        else {
            return []
        }
        let key = fieldAttributeInfo(from: node).key ?? identifier.identifier.text

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
            self._\(identifier) = CKField<\(type)>(wrappedValue: newValue, \(literal: key))
        }
        """

        return [getAccessor, setAccessor, initAccessor]
    }
}
