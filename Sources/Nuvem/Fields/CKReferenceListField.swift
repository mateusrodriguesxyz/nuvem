import CloudKit

@propertyWrapper public struct CKReferenceListField<Value: CKModel>: CKReferenceListFieldProtocol, _CKFieldProtocol {
    
    var hasBeenSet: Bool = false
    
    public var record: CKRecord? { storage.record }
    
    public var recordValue: CKRecordValue?
    
    public var references: [CKRecord.Reference] { recordValue as? [CKRecord.Reference] ?? record?[key] as? [CKRecord.Reference] ?? [] }
    
    var storage: FieldStorage
    
    public let key: String
    
    var referenceForNilRecord: CKRecord.Reference?
    
    var value: [Value]?

    public var wrappedValue: [Value]? {
        get {
            if let value {
                return value
            } else {
                if let records = storage.referenceRecords {
                    return records.map(Value.init)
                } else {
                    return nil
                }
            }
        }
        set {
            hasBeenSet = true
            value = newValue
            if let newValue {
                recordValue = newValue.map({ CKRecord.Reference(record: $0.record, action: .none) }) as CKRecordValue
            }
        }
    }
    
    public var projectedValue: CKReferenceListField<Value> { self }
    
    public init(_ key: String) {
        self.key = key
        self.storage = .init(key: key)
    }
    
    @discardableResult
    public func load(on database: CKDatabase) async throws -> [Value] {
        
        let response = try await database.records(for: references.map(\.recordID))
        
        let records = try references.compactMap {
            if let record = try response[$0.recordID]?.get() {
                return record
            } else {
                return nil
            }
        }
        
        storage.referenceRecords = records
        
        return records.map(Value.init)
        
    }
    
}
