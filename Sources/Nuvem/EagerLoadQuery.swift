import CloudKit

struct EagerLoadQuery<Model> {
    
    let fieldKeyPath: PartialKeyPath<Model>
    
    let desiredKeys: [CKRecord.FieldKey]?
    
    init<Value>(field: KeyPath<Model, CKReferenceFields.Many<Value>>) {
        self.fieldKeyPath = field
        self.desiredKeys = nil
    }
        
    init<Value>(field: KeyPath<Model, CKReferenceFields.One<Value>>) {
        self.fieldKeyPath = field
        self.desiredKeys = nil
    }
    
    init<Value>(field: KeyPath<Model, CKReferenceFields.One<Value>>, desiredFields: PartialKeyPath<Value>...) {
        self.fieldKeyPath = field
        self.desiredKeys = desiredFields.map(\.key)
    }
        
    func run(for referenceFields: [any CKReferenceFieldProtocol], on database: CKDatabase) async throws {
        
        let idsToFetch = Set(referenceFields.compactMap(\.reference?.recordID))
                
        let response = try await database.records(for: Array(idsToFetch), desiredKeys: desiredKeys)
        
        for field in referenceFields {
            if let id = field.reference?.recordID, let record = try response[id]?.get() {
                (field as! _CKFieldProtocol).storage.referenceRecords = [record]
            }
        }
        
    }
    
    func run(for referenceFields: [any CKReferenceListFieldProtocol], on database: CKDatabase) async throws {
        
        let idsToFetch = Set(referenceFields.flatMap({ $0.references.map(\.recordID) }))
        
//        let idsToFetch = Set(referenceFields.compactMap(\.reference?.recordID))
                
        let response = try await database.records(for: Array(idsToFetch), desiredKeys: desiredKeys)
        
        for field in referenceFields {
            let records = try field.references.compactMap { try response[$0.recordID]?.get() }
            (field as! _CKFieldProtocol).storage.referenceRecords = records
        }
        
    }
    
}
