import CloudKit
import Combine

public protocol CKFieldValueMapper<Value> {
    
    associatedtype Value
    
    func get(_ record: CKRecord) -> Value?
    func set(_ value: Value?, _ record: CKRecord)
    
}

public struct KeyedCKFieldValueMapper<Value>: CKFieldValueMapper {
    
    let key: String
    
    let getter: (CKRecordValue?) -> Value?
    let setter: (Value?) -> CKRecordValue?
    
    public func get(_ record: CKRecord) -> Value? {
        getter(record[key])
    }
    
    public func set(_ value: Value?, _ record: CKRecord) {
        record[key] = setter(value)
    }
    
}

@propertyWrapper public class CKField<Value, Mapper>: CKFieldProtocol where Mapper: CKFieldValueMapper<Value> {
    
    public let key: String
    
    public var record: CKRecord! {
        didSet {
            if oldValue == nil, let valueForNilRecord {
                print("updating 'record' with 'valueForNilRecord'")
                mapper.set(valueForNilRecord, record)
            }
        }
    }
    
    private let mapper: Mapper
    
    private let defaultValue: Value?
    
    private var valueForNilRecord: Value?
    
    public var value: Value? {
        mapper.get(record)
    }

    public var wrappedValue: Value {
        get {
            if let recordValue = mapper.get(record) {
                return recordValue
            }
            else if let defaultValue {
                return defaultValue
            }
            else {
                fatalError("wrappedValue must be set before access because it has no default value")
            }
        }
        set {
            publisher.send(newValue)
            if let record {
                mapper.set(newValue, record)
            } else {
                valueForNilRecord = newValue
            }
        }
    }
    
    public var projectedValue: CKField<Value, Mapper> { self }
    
    public lazy var publisher = PassthroughSubject<Value, Never>()
    
    public init(_ key: String, mapper: Mapper) {
        self.key = key
        self.mapper = mapper
        self.defaultValue = nil
    }
    
    public init(_ key: String) where Value: CKFieldValue, Mapper == KeyedCKFieldValueMapper<Value> {
        self.key = key
        self.mapper = KeyedCKFieldValueMapper(key: key, getter: Value.get, setter: Value.set)
        self.defaultValue = nil
    }
    
    func load(on database: CKDatabase) async throws -> Value? {
        let id = record.recordID
        guard let result = try await database.records(for: [id], desiredKeys: [key])[id] else {
            return nil
        }
        self.record[key] = try result.get()[key]
        return wrappedValue
    }
    
}
