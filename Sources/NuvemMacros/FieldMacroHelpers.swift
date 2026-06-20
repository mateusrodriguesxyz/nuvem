import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftDiagnostics

struct FieldPropertyInfo {
    let name: TokenSyntax
    let attribute: AttributeSyntax
    var isReference: Bool {
        ["CKReferenceField", "CKReferenceListField"].contains(attribute.attributeName)
    }
}

struct FieldAttributeInfo {
    let key: String?
}

struct ReferenceFieldAttributeInfo {
    let key: String?
    let action: String?
}

private func extractKey(from node: AttributeSyntax) -> String? {
    node.arguments?.as(LabeledExprListSyntax.self)?
        .first?
        .expression.as(StringLiteralExprSyntax.self)?
        .representedLiteralValue
}

func fieldAttributeInfo(from node: AttributeSyntax) -> FieldAttributeInfo {
    FieldAttributeInfo(key: extractKey(from: node))
}

func referenceFieldAttributeInfo(from node: AttributeSyntax) -> ReferenceFieldAttributeInfo {
    ReferenceFieldAttributeInfo(
        key: extractKey(from: node),
        action: node.arguments?.as(LabeledExprListSyntax.self)?
            .first(where: { $0.label?.text == "action" })?
            .expression.trimmedDescription
    )
}

func hasFieldMacroAttribute(_ variable: VariableDeclSyntax) -> Bool {
    fieldMacroAttribute(variable) != nil
}

func fieldMacroAttribute(_ variable: VariableDeclSyntax) -> AttributeSyntax? {
    for attr in variable.attributes {
        guard case let .attribute(attributeSyntax) = attr else { continue }
        let fieldMacroNames: Set = ["CKField", "CKAssetField", "CKAssetListField", "CKReferenceField", "CKReferenceListField"]
        if fieldMacroNames.contains(attributeSyntax.attributeName.trimmedDescription) {
            return attributeSyntax
        }
    }
    return nil
}

extension VariableDeclSyntax {
    var identifier: IdentifierPatternSyntax? {
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)
    }
    var type: TypeSyntax? {
        bindings.first?.typeAnnotation?.type
    }
}
