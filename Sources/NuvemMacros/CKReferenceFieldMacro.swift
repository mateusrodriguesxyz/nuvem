import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CKReferenceFieldMacro: AccessorMacro, PeerMacro {

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

        let propertyType = typeAnnotation.trimmedDescription
        let modelType = referenceFieldGenericType(from: propertyType)
        let (key, _) = extractFieldArguments(from: node, propertyName: identifier)
        let keyLiteral = "\"\(key)\""

        // var _name = CKReferenceField<Model>("key", action: .none)
        let storageDecl: DeclSyntax = "var _\(raw: identifier) = CKReferenceField<\(raw: modelType)>(\(raw: keyLiteral), action: .none)"

        // var $name: CKReferenceField<Model> { _name.projectedValue }
        let projectedDecl: DeclSyntax = """
        var $\(raw: identifier): CKReferenceField<\(raw: modelType)> { _\(raw: identifier).projectedValue }
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

        let propertyType = typeAnnotation.trimmedDescription
        let modelType = referenceFieldGenericType(from: propertyType)
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
            self._\(raw: identifier) = CKReferenceField<\(raw: modelType)>(wrappedValue: newValue, \(raw: keyLiteral), action: .none)
        }
        """

        return [getAccessor, setAccessor, initAccessor]
    }
}
