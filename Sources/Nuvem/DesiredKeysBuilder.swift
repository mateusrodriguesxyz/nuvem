import CloudKit

final class DesiredKeysBuilder<Model: CKModel> {
    
    var fields: [PartialKeyPath<Model>]?
    var _fields: Fields<Model>?
    
    func add(_ fields: PartialKeyPath<Model>...) {
        if self.fields == nil {
            self.fields = []
        }
        self.fields?.append(contentsOf: fields)
    }
    
    func build() -> [CKRecord.FieldKey]? {
        if let _fields {
            return _fields.desiredKeys
        }
        guard let fields else {
            return nil
        }
        return fields.map(\.key)
    }
     
}
