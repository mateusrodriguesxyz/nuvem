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
        guard
            let property = declaration.as(VariableDeclSyntax.self),
            let identifier = property.identifier,
            let type = property.type
        else {
            return []
        }

        let propertyType = type.trimmedDescription
        let modelType = listFieldGenericType(from: propertyType)

        // var _name: CKReferenceListField<Model>
        let storageDecl: DeclSyntax = "var _\(raw: identifier): CKReferenceListField<\(raw: modelType)>"

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
        guard
            let property = declaration.as(VariableDeclSyntax.self),
            let identifier = property.identifier,
            let type = property.type
        else {
            return []
        }

        let propertyType = type.trimmedDescription
        let modelType = listFieldGenericType(from: propertyType)
        let (key, _) = extractFieldArguments(from: node, propertyName: identifier)
        let keyLiteral = "\"\(key)\""

        // Extract action from attribute, default to .none
        let labelExprList = node.arguments?.as(LabeledExprListSyntax.self) ?? []
        let actionArg = labelExprList.first { $0.label?.text == "action" }
        let actionValue = actionArg?.expression.trimmedDescription ?? ".none"

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
            self._\(raw: identifier) = CKReferenceListField<\(raw: modelType)>(wrappedValue: newValue, \(raw: keyLiteral), action: \(raw: actionValue))
        }
        """

        return [getAccessor, setAccessor, initAccessor]
    }
}
