import CloudKit

@attached(accessor, names: named(`didSet`))
public macro CKAssetField(_ key: String? = nil) = #externalMacro(module: "MacroImplementation", type: "CKAssetFieldMacro")

extension CKFields {
    
    @propertyWrapper public struct Asset<Value: CKAssetFieldValue>: CKFieldProtocol, _CKFieldProtocol {
        
        var hasBeenSet: Bool = false
        
        public var record: CKRecord? { storage.record }
        
        public var recordValue: CKRecordValue?
        
        public var asset: CKAsset? { recordValue as? CKAsset }
        
        var storage: FieldStorage
        
        public let key: String

        var value: Value?

        var defaultValue: Value?

        public var wrappedValue: Value {
            get {
                if let value {
                    return value
                }
                else if
                    let asset = storage.record?[key] as? CKAsset,
                    let url = asset.fileURL,
                    let data = FileManager.default.contents(atPath: url.path)
                {
                    return Value.get(data)!
                }
                else if let defaultValue {
                    return defaultValue
                }
                else {
                    fatalError("wrappedValue must be set before access because it has no default value")
                }
            }
            set {
                hasBeenSet = true
                value = newValue
                if let data = Value.set(newValue) {
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                    do {
                        try data.write(to: url)
                        recordValue = CKAsset(fileURL: url)
                    } catch {
                        print(error)
                        fatalError()
                    }
                } else {
                    recordValue = nil
                }
            }
        }
        
        public var projectedValue: CKFields.Asset<Value> { self }
        
        public init(_ key: String, default defaultValue: Value) {
            self.key = key
            self.defaultValue = defaultValue
            self.storage = .init(key: key)
        }

        public init(_ key: String) {
            self.key = key
            self.storage = .init(key: key)
        }

        public init(_ key: String) where Value: ExpressibleByNilLiteral {
            self.key = key
            self.defaultValue = .some(nil)
            self.storage = .init(key: key)
        }
        
    }
    
}
