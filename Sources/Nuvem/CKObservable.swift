import Foundation
import Observation
import CloudKit
import SwiftUI

@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
@Observable
@dynamicMemberLookup
public final class CKObservable<M: CKModel>: Identifiable {
    public var model: M
    public var id: String { model.id }
    public init(_ model: M) {
        self.model = model
    }
    public subscript<T>(dynamicMember keyPath: KeyPath<M, T>) -> T {
        model[keyPath: keyPath]
    }
}

extension CKModel {
    @available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
    public var observable: CKObservable<Self> {
        .init(self)
    }
}

@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
extension CKObservable {
    public func load<Value>(_ field: KeyPath<M, CKAssetField<Value>>, on database: CKDatabase) async throws {
        let cachedFileURL = URL.cachesDirectory.appendingPathComponent("\(model.id)_\(field.key)")
        let modelModificationDate = model.modificationDate ?? .now
        if
            FileManager.default.fileExists(atPath: cachedFileURL.path(percentEncoded: false)),
            cachedFileURL.modificationDate >= modelModificationDate,
            let data = try? Data(contentsOf: cachedFileURL),
            let cachedValue = Value.get(data)
        {
            self.model[keyPath: field]._update(cachedValue)
            self.model = model
            return
        } else {
            guard let value = try await self.model[keyPath: field].load(on: database) else { return }
            guard let data = Value.set(value) else { return }
            try data.write(to: cachedFileURL)
            self.model[keyPath: field]._update(value)
            self.model = model
        }
    }
    public func load(_ field: KeyPath<M, some CKFieldProtocol>, on database: CKDatabase) async throws {
        let model = self.model
        _ = try await model[keyPath: field].load(on: database)
        self.model = model
    }
    public func load<ReferenceModel>(_ field: KeyPath<ReferenceModel, some CKFieldProtocol>, of reference: KeyPath<M, ReferenceModel?>, on database: CKDatabase) async throws {
        let model = self.model
        let reference = model[keyPath: reference]
        _ = try await reference?[keyPath: field].load(on: database)
        self.model = model
    }
    public func load<Value>(_ field: KeyPath<M, CKReferenceField<Value>>, fields: Fields<Value> = .all, on database: CKDatabase) async throws {
        let model = self.model
        _ = try await model[keyPath: field].load(fields: fields, on: database)
        self.model = model
    }
    public func save(on database: CKDatabase) async throws {
        var model = self.model
        try await model.save(on: database)
        self.model = model
    }
    
    public func delete(on database: CKDatabase) async throws {
        try await model.delete(on: database)
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension Bindable  {
    public subscript<Model, T>(dynamicMember keyPath: WritableKeyPath<Model, T>) -> Binding<T> where Value == CKObservable<Model> {
        projectedValue.model[dynamicMember: keyPath]
    }
    public subscript<Model, T>(dynamicMember keyPath: WritableKeyPath<Model, T?>) -> Binding<T>? where Value == CKObservable<Model> {
        Binding(projectedValue.model[dynamicMember: keyPath])
    }
}

extension URL {
    fileprivate var modificationDate: Date {
        let attributesOfURL = try? FileManager.default.attributesOfItem(atPath: self.path)
        return (attributesOfURL?[FileAttributeKey.modificationDate] as? Date) ?? .now
    }
}
