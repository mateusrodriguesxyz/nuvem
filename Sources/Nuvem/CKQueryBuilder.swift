import CloudKit

public final class CKQueryBuilder<Model> where Model: CKModel {
    
    let database: CKDatabase!
    
    var resultsLimit: Int?
    
    let desiredKeysBuilder = DesiredKeysBuilder<Model>()
    let sortDescriptorsBuilder = SortDescriptorsBuilder<Model>()
    let predicateBuilder = PredicateBuilder<Model>()
    
    var eagerLoadQueries = [EagerLoadQuery<Model>]()
    
    init() {
        self.database = nil
    }
    
    init(database: CKDatabase) {
        self.database = database
    }
    
    public func filter(_ filter: some CKFilter<Model>) -> Self {
        predicateBuilder.add(filter)
        return self
    }
    
    public func sort(_ field: KeyPath<Model, some CKFieldProtocol>, order: CKSort<Model>.Order = .descending) -> Self {
        sortDescriptorsBuilder.add(CKSort(field, order: order))
        return self
    }
    
    public func field(_ field: KeyPath<Model, some CKFieldProtocol>) -> Self {
        desiredKeysBuilder.add(field)
        return self
    }
            
    public func field(
        _ f0: KeyPath<Model, some CKFieldProtocol>,
        _ f1: KeyPath<Model, some CKFieldProtocol>
    ) -> Self {
        desiredKeysBuilder.add(f0, f1)
        return self
    }

    public func field(
        _ f0: KeyPath<Model, some CKFieldProtocol>,
        _ f1: KeyPath<Model, some CKFieldProtocol>,
        _ f2: KeyPath<Model, some CKFieldProtocol>
    ) -> Self {
        desiredKeysBuilder.add(f0, f1, f2)
        return self
    }

    public func field(
        _ f0: KeyPath<Model, some CKFieldProtocol>,
        _ f1: KeyPath<Model, some CKFieldProtocol>,
        _ f2: KeyPath<Model, some CKFieldProtocol>,
        _ f3: KeyPath<Model, some CKFieldProtocol>
    ) -> Self {
        desiredKeysBuilder.add(f0, f1, f2, f3)
        return self
    }

    public func field(
        _ f0: KeyPath<Model, some CKFieldProtocol>,
        _ f1: KeyPath<Model, some CKFieldProtocol>,
        _ f2: KeyPath<Model, some CKFieldProtocol>,
        _ f3: KeyPath<Model, some CKFieldProtocol>,
        _ f4: KeyPath<Model, some CKFieldProtocol>
    ) -> Self {
        desiredKeysBuilder.add(f0, f1, f2, f3, f4)
        return self
    }

    public func field(
        _ f0: KeyPath<Model, some CKFieldProtocol>,
        _ f1: KeyPath<Model, some CKFieldProtocol>,
        _ f2: KeyPath<Model, some CKFieldProtocol>,
        _ f3: KeyPath<Model, some CKFieldProtocol>,
        _ f4: KeyPath<Model, some CKFieldProtocol>,
        _ f5: KeyPath<Model, some CKFieldProtocol>
    ) -> Self {
        desiredKeysBuilder.add(f0, f1, f2, f3, f4, f5)
        return self
    }

    public func field(
        _ f0: KeyPath<Model, some CKFieldProtocol>,
        _ f1: KeyPath<Model, some CKFieldProtocol>,
        _ f2: KeyPath<Model, some CKFieldProtocol>,
        _ f3: KeyPath<Model, some CKFieldProtocol>,
        _ f4: KeyPath<Model, some CKFieldProtocol>,
        _ f5: KeyPath<Model, some CKFieldProtocol>,
        _ f6: KeyPath<Model, some CKFieldProtocol>
    ) -> Self {
        desiredKeysBuilder.add(f0, f1, f2, f3, f4, f5, f6)
        return self
    }

    public func field(
        _ f0: KeyPath<Model, some CKFieldProtocol>,
        _ f1: KeyPath<Model, some CKFieldProtocol>,
        _ f2: KeyPath<Model, some CKFieldProtocol>,
        _ f3: KeyPath<Model, some CKFieldProtocol>,
        _ f4: KeyPath<Model, some CKFieldProtocol>,
        _ f5: KeyPath<Model, some CKFieldProtocol>,
        _ f6: KeyPath<Model, some CKFieldProtocol>,
        _ f7: KeyPath<Model, some CKFieldProtocol>
    ) -> Self {
        desiredKeysBuilder.add(f0, f1, f2, f3, f4, f5, f6, f7)
        return self
    }

    public func field(
        _ f0: KeyPath<Model, some CKFieldProtocol>,
        _ f1: KeyPath<Model, some CKFieldProtocol>,
        _ f2: KeyPath<Model, some CKFieldProtocol>,
        _ f3: KeyPath<Model, some CKFieldProtocol>,
        _ f4: KeyPath<Model, some CKFieldProtocol>,
        _ f5: KeyPath<Model, some CKFieldProtocol>,
        _ f6: KeyPath<Model, some CKFieldProtocol>,
        _ f7: KeyPath<Model, some CKFieldProtocol>,
        _ f8: KeyPath<Model, some CKFieldProtocol>
    ) -> Self {
        desiredKeysBuilder.add(f0, f1, f2, f3, f4, f5, f6, f7, f8)
        return self
    }

    public func field(
        _ f0: KeyPath<Model, some CKFieldProtocol>,
        _ f1: KeyPath<Model, some CKFieldProtocol>,
        _ f2: KeyPath<Model, some CKFieldProtocol>,
        _ f3: KeyPath<Model, some CKFieldProtocol>,
        _ f4: KeyPath<Model, some CKFieldProtocol>,
        _ f5: KeyPath<Model, some CKFieldProtocol>,
        _ f6: KeyPath<Model, some CKFieldProtocol>,
        _ f7: KeyPath<Model, some CKFieldProtocol>,
        _ f8: KeyPath<Model, some CKFieldProtocol>,
        _ f9: KeyPath<Model, some CKFieldProtocol>
    ) -> Self {
        desiredKeysBuilder.add(f0, f1, f2, f3, f4, f5, f6, f7, f8, f9)
        return self
    }
    
    public func with<Value>(_ field: KeyPath<Model, CKReferenceListField<Value>>) -> Self {
        let query = EagerLoadQuery(field: field)
        eagerLoadQueries.append(query)
        return self
    }
    
    public func with<Value>(_ field: KeyPath<Model, CKReferenceField<Value>>) -> Self {
        let query = EagerLoadQuery(field: field)
        eagerLoadQueries.append(query)
        return self
    }
    
    public func with<Value>(
        _ referenceField: KeyPath<Model, CKReferenceField<Value>>,
        _ f0: KeyPath<Value, some CKFieldProtocol>
    ) -> Self {
        let query = EagerLoadQuery(field: referenceField, desiredFields: f0)
        eagerLoadQueries.append(query)
        return self
    }
    
    public func with<Value>(
        _ referenceField: KeyPath<Model, CKReferenceField<Value>>,
        _ f0: KeyPath<Value, some CKFieldProtocol>,
        _ f1: KeyPath<Value, some CKFieldProtocol>
    ) -> Self {
        let query = EagerLoadQuery(field: referenceField, desiredFields: f0, f1)
        eagerLoadQueries.append(query)
        return self
    }

    public func with<Value>(
        _ referenceField: KeyPath<Model, CKReferenceField<Value>>,
        _ f0: KeyPath<Value, some CKFieldProtocol>,
        _ f1: KeyPath<Value, some CKFieldProtocol>,
        _ f2: KeyPath<Value, some CKFieldProtocol>
    ) -> Self {
        let query = EagerLoadQuery(field: referenceField, desiredFields: f0, f1, f2)
        eagerLoadQueries.append(query)
        return self
    }

    public func with<Value>(
        _ referenceField: KeyPath<Model, CKReferenceField<Value>>,
        _ f0: KeyPath<Value, some CKFieldProtocol>,
        _ f1: KeyPath<Value, some CKFieldProtocol>,
        _ f2: KeyPath<Value, some CKFieldProtocol>,
        _ f3: KeyPath<Value, some CKFieldProtocol>
    ) -> Self {
        let query = EagerLoadQuery(field: referenceField, desiredFields: f0, f1, f2, f3)
        eagerLoadQueries.append(query)
        return self
    }

    public func with<Value>(
        _ referenceField: KeyPath<Model, CKReferenceField<Value>>,
        _ f0: KeyPath<Value, some CKFieldProtocol>,
        _ f1: KeyPath<Value, some CKFieldProtocol>,
        _ f2: KeyPath<Value, some CKFieldProtocol>,
        _ f3: KeyPath<Value, some CKFieldProtocol>,
        _ f4: KeyPath<Value, some CKFieldProtocol>
    ) -> Self {
        let query = EagerLoadQuery(field: referenceField, desiredFields: f0, f1, f2, f3, f4)
        eagerLoadQueries.append(query)
        return self
    }
        
    public func limit(_ limit: Int) -> Self {
        resultsLimit = limit
        return self
    }
    
    public func all() async throws -> [Model] {

        var (matchResults, queryCursor) = try await run()
        
        if resultsLimit == nil {
            while queryCursor != nil {
                let response = try await database.records(continuingMatchFrom: queryCursor!)
                queryCursor = response.queryCursor
                matchResults.append(contentsOf: response.matchResults)
            }
        }
        
        let models = try matchResults.map { (_, result) in
            let record = try result.get()
            return Model(record: record)
        }
        
        for query in eagerLoadQueries {
            
            let fields = models.compactMap {
                $0[keyPath: query.fieldKeyPath] as? (any CKReferenceFieldProtocol)
            }
            
            try await query.run(for: fields, on: database)
            
            let fields2 = models.compactMap {
                $0[keyPath: query.fieldKeyPath] as? (any CKReferenceListFieldProtocol)
            }
            
            try await query.run(for: fields2, on: database)
            
        }
        
        return models
        
    }
    
    public func first() async throws -> Model? {
        
        resultsLimit = 1
        
        let (matchResults, _) = try await run()
        
        let model = try matchResults.first.map { (_, result) in
            let record = try result.get()
            return Model(record: record)
        }
        
        for query in eagerLoadQueries {
            
            if let field = model?[keyPath: query.fieldKeyPath] as? (any CKReferenceFieldProtocol) {
                try await query.run(for: [field], on: database)
            }
            
            if let field = model?[keyPath: query.fieldKeyPath] as? (any CKReferenceListFieldProtocol) {
                try await query.run(for: [field], on: database)
            }
            
        }
        
        return model
    }
    
    private func run() async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?) {
        
        let predicate = predicateBuilder.predicate
        let sortDescriptors = sortDescriptorsBuilder.sortDescriptors
        let desiredKeys = desiredKeysBuilder.desiredKeys
        
        let query = CKQuery(recordType: Model.recordType, predicate: predicate)
        
        query.sortDescriptors = sortDescriptors
        
        return try await database.records(
            matching: query,
            desiredKeys: desiredKeys,
            resultsLimit: resultsLimit ?? CKQueryOperation.maximumResults
        )
        
    }
    
}
