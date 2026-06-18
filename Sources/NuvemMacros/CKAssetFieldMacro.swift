import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CKAssetFieldMacro: AccessorMacro, PeerMacro {

    // MARK: - PeerMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let variableDecl = declaration.as(VariableDeclSyntax.self),
              let binding = variableDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
              let typeAnnotation = binding.typeAnnotation?.type
        else {
            return []
        }

        let typeName = typeAnnotation.trimmedDescription
        let (key, defaultValueExpr) = extractFieldArguments(from: node, propertyName: identifier)
        let keyLiteral = "\"\(key)\""

        // var _name = CKAssetField<Type>("key", default: defaultValue)
        let storageDecl: DeclSyntax
        if let defaultValueExpr {
            storageDecl = "var _\(raw: identifier) = CKAssetField<\(raw: typeName)>(\(raw: keyLiteral), default: \(raw: defaultValueExpr))"
        } else {
            storageDecl = "var _\(raw: identifier) = CKAssetField<\(raw: typeName)>(\(raw: keyLiteral))"
        }

        // var $name: CKAssetField<Type> { _name.projectedValue }
        let projectedDecl: DeclSyntax = """
        var $\(raw: identifier): CKAssetField<\(raw: typeName)> { _\(raw: identifier).projectedValue }
        """

        return [storageDecl, projectedDecl]
    }

    // MARK: - AccessorMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let variableDecl = declaration.as(VariableDeclSyntax.self),
              let binding = variableDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
              let typeAnnotation = binding.typeAnnotation?.type
        else {
            return []
        }

        let typeName = typeAnnotation.trimmedDescription
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
            self._\(raw: identifier) = CKAssetField<\(raw: typeName)>(wrappedValue: newValue, \(raw: keyLiteral))
        }
        """

        return [getAccessor, setAccessor, initAccessor]
    }
}
