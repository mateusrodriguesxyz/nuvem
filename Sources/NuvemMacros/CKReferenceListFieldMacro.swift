import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CKReferenceListFieldMacro: AccessorMacro, PeerMacro {

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
        let modelType = listFieldGenericType(from: propertyType)
        let (key, defaultValueExpr) = extractFieldArguments(from: node, propertyName: identifier)
        let keyLiteral = "\"\(key)\""

        // var _name = CKReferenceListField<Model>("key", action: .none)
        // or with default:
        // var _name = CKReferenceListField<Model>("key", default: [], action: .none)
        let storageDecl: DeclSyntax
        if let defaultValueExpr {
            storageDecl = "var _\(raw: identifier) = CKReferenceListField<\(raw: modelType)>(\(raw: keyLiteral), default: \(raw: defaultValueExpr), action: .none)"
        } else {
            storageDecl = "var _\(raw: identifier) = CKReferenceListField<\(raw: modelType)>(\(raw: keyLiteral), action: .none)"
        }

        // var $name: CKReferenceListField<Model> { _name.projectedValue }
        let projectedDecl: DeclSyntax = """
        var $\(raw: identifier): CKReferenceListField<\(raw: modelType)> { _\(raw: identifier).projectedValue }
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
        let modelType = listFieldGenericType(from: propertyType)
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
            self._\(raw: identifier) = CKReferenceListField<\(raw: modelType)>(wrappedValue: newValue, \(raw: keyLiteral), action: .none)
        }
        """

        return [getAccessor, setAccessor, initAccessor]
    }
}
