import CloudKit

public struct CKReferenceListField<Value: CKModel>: CKReferenceListFieldProtocol, _CKFieldProtocol {
    
    var hasBeenSet: Bool = false
    
    public var record: CKRecord? { storage.record }
    
    public var recordValue: CKRecordValue?
    
    public var references: [CKRecord.Reference] { recordValue as? [CKRecord.Reference] ?? record?[key] as? [CKRecord.Reference] ?? [] }
    
    private var action: CKRecord.ReferenceAction
    
    var storage: FieldStorage
    
    public let key: String
    
    var referenceForNilRecord: CKRecord.Reference?
    
    var value: [Value]?
    
    private let defaultValue: [Value]?

    public var wrappedValue: [Value] {
        get {
            if let value {
                return value
            } else {
                if let records = storage.referenceRecords {
                    return records.map(Value.init)
                } else if let defaultValue {
                    return defaultValue
                } else {
                    return []
                }
            }
        }
        set {
            hasBeenSet = true
            value = newValue
            recordValue = newValue.map({ CKRecord.Reference(record: $0.record, action: action) }) as CKRecordValue
        }
    }
    
    public var projectedValue: CKReferenceListField<Value> { self }
    
    public init(_ key: String, action: CKRecord.ReferenceAction = .none) {
        self.key = key
        self.defaultValue = nil
        self.storage = .init(key: key)
        self.action = action
    }
    
    public init(wrappedValue: [Value], _ key: String, action: CKRecord.ReferenceAction = .none) {
        self.key = key
        self.defaultValue = wrappedValue
        self.storage = .init(key: key)
        self.action = action
    }

    public init(_ key: String, default defaultValue: [Value], action: CKRecord.ReferenceAction = .none) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = .init(key: key)
        self.action = action
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
