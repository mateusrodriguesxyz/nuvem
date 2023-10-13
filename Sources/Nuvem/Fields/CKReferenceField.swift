@attached(accessor, names: named(`didSet`))
public macro CKReferenceField(_ key: String? = nil) = #externalMacro(module: "MacroImplementation", type: "CKReferenceFieldMacro")

public enum CKReferenceField {
    public typealias One = CKReferenceFieldOne
    public typealias Many = CKReferenceFieldMany
}
