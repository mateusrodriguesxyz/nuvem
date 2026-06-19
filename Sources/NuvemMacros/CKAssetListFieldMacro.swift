import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CKAssetListFieldMacro: AccessorMacro, PeerMacro {

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

        let propertyType = type.trimmedDescription
        let elementType = listFieldGenericType(from: propertyType)

        // var _name: CKAssetListField<Element>
        let storageDecl: DeclSyntax = "var _\(raw: identifier): CKAssetListField<\(raw: elementType)>"

        // var $name: CKAssetListField<Element> { _name.projectedValue }
        let projectedDecl: DeclSyntax = """
        var $\(raw: identifier): CKAssetListField<\(raw: elementType)> { _\(raw: identifier).projectedValue }
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

        let propertyType = type.trimmedDescription
        let elementType = listFieldGenericType(from: propertyType)
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
            self._\(raw: identifier) = CKAssetListField<\(raw: elementType)>(wrappedValue: newValue, \(raw: keyLiteral))
        }
        """

        return [getAccessor, setAccessor, initAccessor]
    }
}
