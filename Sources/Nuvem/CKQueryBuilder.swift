import CloudKit
import CryptoKit
import Combine

public final class CKQueryBuilder<Model> where Model: CKModel {
    
    let database: CKDatabase!
    
    private var resultsLimit: Int?
    
    let desiredKeysBuilder = DesiredKeysBuilder<Model>()
    let sortDescriptorsBuilder = SortDescriptorsBuilder<Model>()
    let predicateBuilder = PredicateBuilder<Model>()
    
    var referenceQueries = [ReferenceQuery<Model>]()
    
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
    
    public func field<each T: CKFieldProtocol>(_ fields: repeat KeyPath<Model, each T>) -> Self {
        desiredKeysBuilder.add()
        for field in repeat each fields {
            desiredKeysBuilder.add(field)
        }
        return self
    }

    @_disfavoredOverload
    public func field<each T: CKFieldProtocol>(exclude fields: repeat KeyPath<Model, each T>) -> Self {
        desiredKeysBuilder.add()
        var fieldsToExclude = [PartialKeyPath<Model>]()
        for field in repeat each fields {
            fieldsToExclude.append(field)
        }
        let fieldKeysToExclude = fieldsToExclude.map { $0.key }
        let allKeyPaths = Model().allKeyPaths.values
        for keyPath in allKeyPaths {
            if let _field = Model()[keyPath: keyPath] as? (any _CKFieldProtocol), !fieldKeysToExclude.contains(_field.key) {
                desiredKeysBuilder.add(keyPath)
            }
        }
        return self
    }
    
    public func fields(_ fields: Fields<Model> = .all) -> Self {
        desiredKeysBuilder._fields = fields
        return self
    }
    
    public func with<Value>(_ field: KeyPath<Model, CKReferenceListField<Value>>) -> Self {
        let query = ReferenceQuery(field: field)
        referenceQueries.append(query)
        return self
    }
    
    public func with<Value>(_ field: KeyPath<Model, CKReferenceField<Value>>) -> Self {
        let query = ReferenceQuery(field: field)
        referenceQueries.append(query)
        return self
    }
    
    public func with<each T: CKFieldProtocol>(_ fields: repeat KeyPath<Model, CKReferenceField<each T>>) -> Self {
        for field in repeat each fields {
            let query = ReferenceQuery(field: field)
            referenceQueries.append(query)
        }
        return self
    }
    
    public func with<Value, each T: CKFieldProtocol>(
        _ referenceField: KeyPath<Model, CKReferenceField<Value>>,
        _ fields: repeat KeyPath<Value, each T>
    ) -> Self {
        var desiredFields = [PartialKeyPath<Value>]()
        for field in repeat each fields {
            desiredFields.append(field)
        }
        let query = ReferenceQuery(field: referenceField, desiredFields: desiredFields)
        referenceQueries.append(query)
        return self
    }
    
    public func with<Value>(_ field: KeyPath<Model, CKReferenceField<Value>>, fields: Fields<Value>) -> Self {
        let query = ReferenceQuery(field: field, desiredKeys: fields.desiredKeys)
        referenceQueries.append(query)
        return self
    }
    
    public func with<Value, each T: CKFieldProtocol>(
        _ referenceField: KeyPath<Model, CKReferenceField<Value>>,
        exclude fields: repeat KeyPath<Value, each T>
    ) -> Self {
        var fieldsToExclude = [PartialKeyPath<Value>]()
        for field in repeat each fields {
            fieldsToExclude.append(field)
        }
        let fieldKeysToExclude = fieldsToExclude.map { $0.key }
        let allKeyPaths = Value().allKeyPaths.values
        var desiredFields = [PartialKeyPath<Value>]()
        for keyPath in allKeyPaths {
            if let _field = Value()[keyPath: keyPath] as? (any _CKFieldProtocol), !fieldKeysToExclude.contains(_field.key) {
                desiredFields.append(keyPath)
            }
        }
        let query = ReferenceQuery(field: referenceField, desiredFields: desiredFields)
        referenceQueries.append(query)
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
        
        try await loadReferences(models)
        
        return models
        
    }
    
    public func batch(continuing queryCursor: CKQueryOperation.Cursor? = nil) async throws -> ([Model], CKQueryOperation.Cursor?) {
             
        var queryCursor = queryCursor
        
        var matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)]  = []
        
        if queryCursor == nil {
            (matchResults, queryCursor) = try await run()
        } else {
            let response = try await database.records(continuingMatchFrom: queryCursor!, resultsLimit: resultsLimit ?? CKQueryOperation.maximumResults)
            queryCursor = response.queryCursor
            matchResults.append(contentsOf: response.matchResults)
        }
        
        let models = try matchResults.map { (_, result) in
            let record = try result.get()
            return Model(record: record)
        }
        
        try await loadReferences(models)
        
        return (models, queryCursor)
        
    }
    
    public func first() async throws -> Model? {
        try await self.limit(1).all().first
    }
    
    public func build() -> (query: CKQuery, desiredKeys: [CKRecord.FieldKey]?) {
        let predicate = predicateBuilder.build()
        let sortDescriptors = sortDescriptorsBuilder.build()
        let desiredKeys = desiredKeysBuilder.build()
        let query = CKQuery(recordType: Model.recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors
        return (query, desiredKeys)
    }
    
    public func batched() -> Batched {
        Batched(self)
    }
    
    private func run() async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?) {
        let (query, desiredKeys) = self.build()
        return try await database.records(
            matching: query,
            desiredKeys: desiredKeys,
            resultsLimit: resultsLimit ?? CKQueryOperation.maximumResults
        )
    }
    
    func loadReferences(_ models: [Model]) async throws {
        for query in referenceQueries {
            let fields = models.compactMap {
                $0[keyPath: query.fieldKeyPath] as? (any CKReferenceFieldProtocol)
            }
            try await query.run(for: fields, on: database)
            let fields2 = models.compactMap {
                $0[keyPath: query.fieldKeyPath] as? (any CKReferenceListFieldProtocol)
            }
            try await query.run(for: fields2, on: database)
        }
    }
    
}

extension CKQueryBuilder {
    
    public final class Batched {
        
        let builder: CKQueryBuilder<Model>
        
        private var isInitialFetch = true
        private var queryCursor: CKQueryOperation.Cursor?
        
        public var hasBatchAvailable: Bool {
            isInitialFetch || queryCursor != nil
        }
        
        init(_ builder: CKQueryBuilder<Model>) {
            self.builder = builder
        }
        
        public func next(_ resultsLimit: Int? = nil) async throws -> [Model]? {
            if !isInitialFetch, queryCursor == nil {
                return nil
            }
            guard let database = builder.database else { return nil }
            let (query, _) = builder.build()
            var matchResults: [(CKRecord.ID, Result<CKRecord, Error>)]
            if isInitialFetch {
                (matchResults, queryCursor) = try await database.records(
                    matching: query,
                    resultsLimit: resultsLimit ?? CKQueryOperation.maximumResults
                )
                isInitialFetch = false
            } else {
                (matchResults, queryCursor) = try await database.records(
                    continuingMatchFrom: queryCursor!,
                    resultsLimit: resultsLimit ?? CKQueryOperation.maximumResults
                )
            }
            let models = try matchResults.map { (_, result) in
                let record = try result.get()
                return Model(record: record)
            }
            try await builder.loadReferences(models)
            return models
        }
        
        public func reset() {
            isInitialFetch = true
            queryCursor = nil
        }
        
    }
    
}
