import CloudKit

@propertyWrapper public struct CKAssetField<Value: CKAssetFieldValue>: CKFieldProtocol, _CKFieldProtocol {
    
    enum Source {
        case storage
        case record
        case field
    }
    
    var hasBeenSet: Bool = false
    
    public var record: CKRecord? { storage.record }
    
    public var recordValue: CKRecordValue?
    
    public var asset: CKAsset? { recordValue as? CKAsset }
    
    var storage: FieldStorage
    
    public let key: String

    var value: Value?

    var defaultValue: Value?
    
    var _wrappedValue: (Value, Source) {
        fatalError()
    }

    public var wrappedValue: Value {
        get {
            if let value {
                print("value from local")
                return value
            }
            else if storage.loadedValue != nil, let loadedValue = storage.loadedValue as? Value {
                print("value from storage")
                return loadedValue
            }
            else if
                let asset = storage.record?[key] as? CKAsset,
                let fileURL = asset.fileURL,
                let data = FileManager.default.contents(atPath: fileURL.path)
            {
                clearOldFiles(fileURL)
                let value = Value.get(data)!
                storage.loadedValue = value
                print("value from record")
                return value
            }
            else if let defaultValue {
                print("value from default")
                return defaultValue
            }
            else {
                fatalError("wrappedValue must be set before access because it has no default value")
            }
        }
        set {
            hasBeenSet = true
            value = newValue
            if let data = Value.set(newValue) {
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                do {
                    try data.write(to: url)
                    recordValue = CKAsset(fileURL: url)
                } catch {
                    print(error)
                    fatalError()
                }
            } else {
                recordValue = nil
            }
        }
    }
    
    public var projectedValue: CKAssetField<Value> { self }
    
    public init(_ key: String, default defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = .init(key: key)
    }

    public init(_ key: String) {
        self.key = key
        self.storage = .init(key: key)
    }

    public init(_ key: String) where Value: ExpressibleByNilLiteral {
        self.key = key
        self.defaultValue = .some(nil)
        self.storage = .init(key: key)
    }
    
    @discardableResult
    public func load(on database: CKDatabase) async throws -> Value? {
        guard let record = storage.record else { return nil }
        let id = record.recordID
        guard let result = try await database.records(for: [id], desiredKeys: [key])[id] else {
            return nil
        }
        record[key] = try result.get()[key]
        return wrappedValue
    }
    
    private func clearOldFiles(_ fileURL: URL) {
        DispatchQueue.global().async {
            let cloudKitCachesDirectory = fileURL.deletingLastPathComponent().absoluteString.replacingOccurrences(of: "file://", with: "")
            do {
                guard FileManager.default.fileExists(atPath: cloudKitCachesDirectory) else { return }
                let files = try FileManager.default.contentsOfDirectory(atPath: cloudKitCachesDirectory)
                let oldFiles = files.filter {
                    let newFile = fileURL.lastPathComponent
                    let id = newFile.drop(while: { $0 != "." }).dropFirst()
                    return $0.contains(id) && $0 != newFile
                }
                try oldFiles.forEach {
                    try FileManager.default.removeItem(atPath: cloudKitCachesDirectory + $0)
                }
            } catch {
                print(error)
            }
        }
    }
    
}
