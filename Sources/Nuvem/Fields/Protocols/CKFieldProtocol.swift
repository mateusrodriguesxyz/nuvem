import CloudKit

public protocol CKFieldProtocol {
    associatedtype Value
    var key: String { get }
    var record: CKRecord? { get }
    func load(on database: CKDatabase) async throws -> Value
}

extension KeyPath where Root: CKModel, Value: CKFieldProtocol {
    public var key: String { Root()[keyPath: self].key }
}

extension PartialKeyPath where Root: CKModel {
    @_disfavoredOverload
    var key: String { (Root()[keyPath: self] as! any CKFieldProtocol).key }
}

protocol _CKFieldProtocol: CKFieldProtocol {
    var hasBeenSet: Bool { get }
    var recordValue: CKRecordValue? { get set }
    var storage: FieldStorage { get }
    func updateRecord()
}


extension _CKFieldProtocol {
    func updateRecord() {
        guard hasBeenSet else { return }
        storage.update(with: recordValue)
    }
}
