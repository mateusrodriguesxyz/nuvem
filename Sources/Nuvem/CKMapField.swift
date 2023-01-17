import CloudKit

public protocol CKFieldValueMapper<Value> {
    
    associatedtype Value
    
    func get(_ record: CKRecord) -> Value?
    func set(_ value: Value?, _ record: CKRecord)
    
}

@propertyWrapper public class CKMapField<Value, Mapper: CKFieldValueMapper> where Mapper.Value == Value  {
    
    public var record: CKRecord? {
        didSet {
            if oldValue == nil, let record, let valueForNilRecord {
                print("updating 'record' with 'valueForNilRecord'")
                mapper.set(valueForNilRecord, record)
            }
        }
    }
    
    public var mapper: Mapper
    
    private let defaultValue: Value?
    
    private var valueForNilRecord: Value?
    
    public var value: Value? {
        if let record {
            return mapper.get(record)
        } else {
            return nil
        }
    }

    public var wrappedValue: Value {
        get {
            if let record, let recordValue = mapper.get(record) {
                return recordValue
            }
            else if let valueForNilRecord {
                return valueForNilRecord
            }
            else if let defaultValue {
                return defaultValue
            }
            else {
                fatalError("wrappedValue must be set before access because it has no default value")
            }
        }
        set {
            if let record {
                mapper.set(newValue, record)
            } else {
                valueForNilRecord = newValue
            }
        }
    }
    
    public var projectedValue: CKMapField<Value, Mapper> { self }
        
    public init(mapper: Mapper, default defaultValue: Value) {
        self.mapper = mapper
        self.defaultValue = defaultValue
    }
    
//    func load(on database: CKDatabase) async throws -> Value? {
//        let id = record.recordID
//        guard let result = try await database.records(for: [id], desiredKeys: [key])[id] else {
//            return nil
//        }
//        self.record[key] = try result.get()[key]
//        return wrappedValue
//    }
    
}
