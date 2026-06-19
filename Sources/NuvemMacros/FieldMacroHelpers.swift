import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftDiagnostics

/// Extracts the key string and optional default value expression from a field macro attribute.
///
/// Supported forms:
/// - `@CKField("key")` → key: "key", defaultValue: nil
/// - `@CKField("key", default: value)` → key: "key", defaultValue: "value"
///
/// If no explicit key is given, the property name is used.
func extractFieldArguments(from node: AttributeSyntax, propertyName: String) -> (key: String, defaultValue: String?) {
    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
        return (propertyName, nil)
    }

    var key: String?
    var defaultValue: String?

    for argument in arguments {
        if let label = argument.label?.text {
            switch label {
            case "default":
                defaultValue = argument.expression.trimmedDescription
            default:
                break
            }
        } else {
            key = argument.expression.as(StringLiteralExprSyntax.self)?.representedLiteralValue
        }
    }

    return (key ?? propertyName, defaultValue)
}

/// Strips Optional<T> → T from a type string.
/// Handles both `Optional<T>` and `T?` syntax.
func stripOptional(from typeName: String) -> String {
    if typeName.hasSuffix("?") {
        return String(typeName.dropLast()).trimmingCharacters(in: .whitespaces)
    }
    // Optional<Type>
    let prefix = "Optional<"
    if typeName.hasPrefix(prefix), typeName.hasSuffix(">") {
        return String(typeName.dropFirst(prefix.count).dropLast())
    }
    return typeName
}

/// Strips [T] → T from a type string (array syntax).
func stripArray(from typeName: String) -> String {
    let trimmed = typeName.trimmingCharacters(in: .whitespaces)
    if trimmed.hasPrefix("["), trimmed.hasSuffix("]") {
        return String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
    }
    // Array<Type>
    let prefix = "Array<"
    if trimmed.hasPrefix(prefix), trimmed.hasSuffix(">") {
        return String(trimmed.dropFirst(prefix.count).dropLast()).trimmingCharacters(in: .whitespaces)
    }
    return trimmed
}

/// Checks if a type string represents an optional type.
/// Returns true for `T?`, `Optional<T>`, and nested forms like `[T]?`.
func isOptionalType(_ typeName: String) -> Bool {
    let trimmed = typeName.trimmingCharacters(in: .whitespaces)
    return trimmed.hasSuffix("?") || trimmed.hasPrefix("Optional<")
}

/// Known field macro attribute names.
private let fieldMacroNames: Set = ["CKField", "CKAssetField", "CKAssetListField", "CKReferenceField", "CKReferenceListField"]

/// Returns true if a variable declaration has a field macro attribute.
func hasFieldMacroAttribute(_ variable: VariableDeclSyntax) -> Bool {
    fieldMacroAttribute(variable) != nil
}

/// Returns the field macro `AttributeSyntax` if the variable declaration has one, otherwise nil.
func fieldMacroAttribute(_ variable: VariableDeclSyntax) -> AttributeSyntax? {
    for attr in variable.attributes {
        guard case let .attribute(attributeSyntax) = attr else { continue }
        if fieldMacroNames.contains(attributeSyntax.attributeName.trimmedDescription) {
            return attributeSyntax
        }
    }
    return nil
}

/// Decides the backing generic type for a reference field.
/// For `M2?` returns `M2`. For `M2` returns `M2` (shouldn't happen).
func referenceFieldGenericType(from propertyType: String) -> String {
    stripOptional(from: propertyType)
}

/// Decides the backing generic type for a list field (asset or reference).
/// For `[Data]` returns `Data`. For `[M2]` returns `M2`.
func listFieldGenericType(from propertyType: String) -> String {
    stripArray(from: propertyType)
}

extension VariableDeclSyntax {
    var identifier: String? {
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
    }
    var type: TypeSyntax? {
        bindings.first?.typeAnnotation?.type
    }
}

/// Warning reported when a non-field, non-optional stored property lacks a default value.
struct NonOptionalPropertyWarning: DiagnosticMessage {
    let propertyName: String
    var message: String {
        "@CKModel requires non-optional property '\(propertyName)' to have a default value"
    }
    var diagnosticID: MessageID { MessageID(domain: "NuvemMacros", id: "nonOptionalProperty") }
    var severity: DiagnosticSeverity { .error }
}
