import CloudKit
import SwiftUI

public protocol CKModel: Identifiable where ID == String {
    static var recordType: CKRecord.RecordType { get }
    var record: CKRecord! { get set }
    init()
}

extension CKModel {
    
    public static var recordType: CKRecord.RecordType { String(describing: Self.self) }
    
    public var id: String { record.recordID.recordName }
    
    public var modificationDate: Date? { record.modificationDate }
    
    public var creationDate: Date? { record.creationDate }
    
    init(record: CKRecord) {
        self.init()
        self.record = record
        bindRecordToFields()
    }
    
}

extension CKModel {
    
    subscript(checkedMirrorDescendant key: String) -> Any {
        return Mirror(reflecting: self).descendant(key)!
    }
    
    var allKeyPaths: [String: PartialKeyPath<Self>] {
        var allKeyPaths = [String: PartialKeyPath<Self>]()
        let mirror = Mirror(reflecting: self)
        for case (let key?, _) in mirror.children {
            allKeyPaths[key] = \Self.[checkedMirrorDescendant: key] as PartialKeyPath
        }
        return allKeyPaths
    }
    
    var allFields: [any _CKFieldProtocol] {
        allKeyPaths.values.compactMap { self[keyPath: $0] as? (any _CKFieldProtocol) }
    }
    
    func bindRecordToFields() {
        for field in allFields {
            assert(field.storage.record == nil)
            field.storage.record = self.record
        }
    }
    
    func updateRecordWithFields() {
        for field in allFields {
            field.storage.record = self.record
//            assert(field.storage.record != nil)
            field.updateRecord()
        }
    }
    
}

extension CKModel {
    
    mutating func _save() {
        if record == nil {
            record = CKRecord(recordType: Self.recordType)
        }
        updateRecordWithFields()
    }
    
    public static func find(id: CKRecord.ID, on database: CKDatabase) async throws -> Self {
        let record = try await database.record(for: id)
        let model = Self(record: record)
        return model
    }
    
    public static func find<Value>(id: CKRecord.ID, with field: KeyPath<Self, CKReferenceListField<Value>>, on database: CKDatabase) async throws -> Self {
        let query = EagerLoadQuery(field: field)
        let record = try await database.record(for: id)
        let model = Self(record: record)
        if let field = model[keyPath: query.fieldKeyPath] as? (any CKReferenceListFieldProtocol) {
            try await query.run(for: [field], on: database)
        }
        return model
    }
    
    public static func query(on database: CKDatabase) -> CKQueryBuilder<Self> {
        return CKQueryBuilder(database: database)
    }
    
    public mutating func save(on database: CKDatabase) async throws {
        _save()
        self.record = try await database.save(record)
    }
    
    public func delete(on database: CKDatabase) async throws {
        try await database.deleteRecord(withID: record.recordID)
    }
    
}

extension Binding where Value: CKModel {

    // MARK: TODO - 🤔
    @MainActor
    public func save(on database: CKDatabase) async throws {
        try await wrappedValue.save(on: database)
    }
    
}
