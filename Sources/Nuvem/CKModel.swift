import CloudKit
import SwiftUI

@attached(member, names: named(recordType), named(record), named(creationDate), named(modificationDate), named(init), named(Observable))
@attached(memberAttribute)
@attached(extension, conformances: CKModel)
public macro CKModel(_ name: String? = nil) = #externalMacro(module: "NuvemMacros", type: "CKModelMacro")

public protocol CKModel: CustomDebugStringConvertible, Identifiable where ID == String {
    static var recordType: CKRecord.RecordType { get }
    var record: CKRecord! { get set }
    init()
}

extension CKModel {
    public var debugDescription: String {
        "\(Self.self)"
    }
}

extension CKModel {
    
    public static var recordType: CKRecord.RecordType { String(describing: Self.self) }
    
    public var id: String { record.recordID.recordName }
    
    public var modificationDate: Date? { record.modificationDate }
    
    public var creationDate: Date? { record.creationDate }
    
    public init(record: CKRecord) {
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
    
    public static func find<each T: CKFieldProtocol>(id: CKRecord.ID, fields: repeat KeyPath<Self, each T>?, on database: CKDatabase) async throws -> Self {
        let desiredKeysBuilder = DesiredKeysBuilder<Self>()
        desiredKeysBuilder.add()
        for field in repeat each fields {
            if let field {
                desiredKeysBuilder.add(field)
            }
        }
        let record = try await database.records(for: [id], desiredKeys: desiredKeysBuilder.build())[id]!.get()
        let model = Self(record: record)
        return model
    }
    
    public static func find<Value>(id: CKRecord.ID, with field: KeyPath<Self, CKReferenceListField<Value>>, on database: CKDatabase) async throws -> Self {
        let query = ReferenceQuery(field: field)
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
//        NotificationCenter.default.post(name: Notification.Name("CKQueryRemoteNotification"), object: nil)
    }
    
    public func delete(on database: CKDatabase) async throws {
        try await database.deleteRecord(withID: record.recordID)
    }
    
}

extension [CKModel] {
    
    public mutating func save(on database: CKDatabase) async throws {
        for index in self.indices {
            self[index]._save()
        }
        let (results, _) = try await database.modifyRecords(saving: self.compactMap(\.record), deleting: [])
        for index in self.indices {
            let model = self[index]
            self[index].record = try results[model.record.recordID]?.get()
        }
    }
    
    public mutating func delete(on database: CKDatabase) async throws {
        for index in self.indices {
            self[index]._save()
        }
        let _ = try await database.modifyRecords(saving: [], deleting: self.compactMap(\.record?.recordID))
    }
    
}

extension Binding where Value: CKModel {
    public func save(on database: CKDatabase) async throws {
        try await wrappedValue.save(on: database)
    }
//    @_disfavoredOverload
//    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> Binding<T> {
//       Binding<T>(
//            get: {
//                wrappedValue[keyPath: keyPath]
//            },
//            set: { newValue in
//                var value = wrappedValue
//                value[keyPath: keyPath] = newValue
//                wrappedValue = value
//            },
//       )
//    }
}

extension Binding where Value: CKFieldProtocol {
    public func load(on database: CKDatabase) async throws {
        let value = self.wrappedValue
        _ = try await value.load(on: database)
        self.wrappedValue = value
    }
}

extension Binding where Value: CKModel {
    public func load(_ field: KeyPath<Value, some CKFieldProtocol>, on database: CKDatabase) async throws {
        let value = self.wrappedValue
        _ = try await value[keyPath: field].load(on: database)
        self.wrappedValue = value
    }
}
