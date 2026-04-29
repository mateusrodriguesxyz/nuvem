import CloudKit

@propertyWrapper public struct CKAssetListField<Value: CKAssetFieldValue>: CKAssetListFieldProtocol, _CKFieldProtocol {

    var hasBeenSet: Bool = false

    public var record: CKRecord? { storage.record }

    public var recordValue: CKRecordValue?

    public var assets: [CKAsset] {
        recordValue as? [CKAsset] ?? storage.record?[key] as? [CKAsset] ?? []
    }

    var storage: FieldStorage

    public let key: String

    var value: [Value]?

    var defaultValue: [Value]?

    public var wrappedValue: [Value] {
        get {
            if let value {
                return value
            }
            else if storage.loadedValue != nil, let loadedValue = storage.loadedValue as? [Value] {
                return loadedValue
            }
            else if let assets = storage.record?[key] as? [CKAsset] {
                let values = assets.compactMap { asset -> Value? in
                    guard let fileURL = asset.fileURL,
                          let data = FileManager.default.contents(atPath: fileURL.path) else {
                        return nil
                    }
                    clearOldFiles(fileURL)
                    return Value.get(data)
                }
                storage.loadedValue = values
                return values
            }
            else if let defaultValue {
                return defaultValue
            }
            else {
                fatalError("wrappedValue must be set before access because it has no default value")
            }
        }
        set {
            hasBeenSet = true
            value = newValue
        }
    }

    public var projectedValue: CKAssetListField<Value> {
        get {
            self
        }
        set {
            self = newValue
        }
    }

    public init(_ key: String, default defaultValue: [Value]) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = .init(key: key)
    }

    public init(_ key: String) {
        self.key = key
        self.storage = .init(key: key)
    }

    @discardableResult
    public func load(on database: CKDatabase) async throws -> [Value] {
        guard let record = storage.record else { return [] }
        let id = record.recordID
        guard let result = try await database.records(for: [id], desiredKeys: [key])[id] else {
            return wrappedValue
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
                print("OLD FILES: \(oldFiles.count)")
            } catch {
                print(error)
            }
        }
    }

    public func _update(_ value: [Value]) {
        self.storage.loadedValue = value
    }

}

extension CKAssetListField {
    func updateRecord() {
        guard hasBeenSet else { return }
        if let value {
            let assets = value.compactMap { value -> CKAsset? in
                guard let data = Value.set(value) else { return nil }
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                do {
                    try data.write(to: url)
                    return CKAsset(fileURL: url)
                } catch {
                    print(error)
                    return nil
                }
            }
            if assets.isEmpty {
                storage.update(with: nil)
            } else {
                storage.update(with: assets as NSArray)
            }
        } else {
            storage.update(with: nil)
        }
    }
}
