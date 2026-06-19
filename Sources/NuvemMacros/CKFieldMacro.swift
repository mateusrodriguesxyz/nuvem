import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CKFieldMacro: AccessorMacro, PeerMacro {

    // MARK: - PeerMacro

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

        let typeName = type.trimmedDescription

        // var _name: CKField<Type>
        let storageDecl: DeclSyntax = "var _\(raw: identifier): CKField<\(raw: typeName)>"

        // var $name: CKField<Type> { _name.projectedValue }
        let projectedDecl: DeclSyntax = """
        var $\(raw: identifier): CKField<\(raw: typeName)> { _\(raw: identifier).projectedValue }
        """

        return [storageDecl, projectedDecl]
    }

    // MARK: - AccessorMacro

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

        let typeName = type.trimmedDescription
        let (key, _) = extractFieldArguments(from: node, propertyName: identifier)
        let keyLiteral = "\"\(key)\""

        let getAccessor: AccessorDeclSyntax = """
        get {
            _\(raw: identifier).wrappedValue
        }
        """

        let setAccessor: AccessorDeclSyntax = """
        set {
            _\(raw: identifier).wrappedValue = newValue
        }
        """

        let initAccessor: AccessorDeclSyntax = """
        @storageRestrictions(initializes: _\(raw: identifier))
        init {
            self._\(raw: identifier) = CKField<\(raw: typeName)>(wrappedValue: newValue, \(raw: keyLiteral))
        }
        """

        return [getAccessor, setAccessor, initAccessor]
    }
}
