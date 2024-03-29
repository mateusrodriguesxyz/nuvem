import CloudKit

@propertyWrapper public struct CKReferenceField<Value: CKModel>: CKReferenceFieldProtocol, _CKFieldProtocol {
    
    var hasBeenSet: Bool = false
    
    public var record: CKRecord? { storage.record }
    
    public var recordValue: CKRecordValue?
    
    public var reference: CKRecord.Reference? { recordValue as? CKRecord.Reference ?? record?[key] as? CKRecord.Reference  }
    
    var storage: FieldStorage
    
    public let key: String
    
    var referenceForNilRecord: CKRecord.Reference?
    
    var value: Value?

    public var wrappedValue: Value? {
        get {
            if let value {
                return value
            } else {
                return storage.referenceRecords?.first.map(Value.init)
            }
        }
        set {
            hasBeenSet = true
            value = newValue
            recordValue = newValue.map({ CKRecord.Reference(record: $0.record, action: .none) })
        }
    }
    
    public var projectedValue: CKReferenceField<Value> { self }
    
    public init(_ key: String) {
        self.key = key
        self.storage = .init(key: key)
    }
    
    @discardableResult
    public func load(on database: CKDatabase) async throws -> Value? {
        guard let reference else { return nil }
        let record = try await database.record(for: reference.recordID)
        return Value.init(record: record)
    }
    
}
