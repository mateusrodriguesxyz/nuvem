import SwiftUI
import CloudKit
import Combine

@available(iOS 16.0, *)
@propertyWrapper
public struct NVQuery<T: CKModel>: DynamicProperty {
    
    enum Change {
        case created(record: CKRecord)
        case updated(record: CKRecord, index: Int)
        case deleted(index: Int)
    }
    
    private final class Store {
        var cancellable: Cancellable?
    }
    
    @State private var values: [T]?
    
    public var wrappedValue: [T] {
        get {
            return values ?? []
        }
    }
    
    let database: CKDatabase
    
    let query: CKQueryBuilder<T>
    
    private let store = Store()
    
    public init(database: CKDatabase, _ query: (CKQueryBuilder<T>) -> CKQueryBuilder<T> = { $0 }) {
        self.database = database
        self.query = query(T.query(on: database))
    }
    
    public func update() {
        if values == nil {
            Task {
                try await refresh()
                try await subscribe()
            }
        }
    }
    
    public func refresh() async throws {
        let values = try await query.all()
        self.values = values
    }
    
    private func subscribe() async throws {
                
        let subscriptionID = T.subscriptionID
        
        store.cancellable = NotificationCenter.default.publisher(for: .init("CKQueryRemoteNotification"))
            .compactMap { $0.userInfo?["notification"] as? CKQueryNotification }
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.global())
//            .buffer(size: 10, prefetch: .keepFull, whenFull: .dropOldest)
            .flatMap { notification in
                Future<[T], Never> { promise in
                    Task {
                        guard notification.subscriptionID == subscriptionID else {
                            return
                        }
                        if notification.queryNotificationReason == .recordCreated {
                            try await Task.sleep(for: .seconds(1))
                        }
                        let values = try await query.all()
                        promise(.success(values))
                    }
                }
            }
            .sink { values in
                withAnimation {
                    self.values = values
                }
            }
        
        try await T.makeCKQuerySubscription(query: query.build().0, on: database)
    
    }
    
}

public final class AnyCKModel: CKModel {
    public var record: CKRecord!
    public init() { }
}

@available(iOS 16.0, *)
extension NVQuery where T == AnyCKModel {
    public static func applicationDidReceiveRemoteNotification(_ userInfo: [AnyHashable : Any]) {
        if let notification = CKQueryNotification(fromRemoteNotificationDictionary: userInfo) {
            NotificationCenter.default.post(
                name: Notification.Name("CKQueryRemoteNotification"),
                object: nil,
                userInfo: ["notification": notification]
            )
        }
    }
}

extension CKModel {
    
    public static var subscriptionID: CKSubscription.ID { "\(Self.self).Changes" }
    
    public static func makeCKQuerySubscription(query: CKQuery? = nil, on database: CKDatabase) async throws {
        let subscriptionID = Self.subscriptionID
        if UserDefaults.standard.bool(forKey: subscriptionID) {
            return
        }
        let subscription = CKQuerySubscription(
            recordType: Self.recordType,
            predicate: query?.predicate ?? NSPredicate(value: true),
            subscriptionID: subscriptionID,
            options: [
                .firesOnRecordCreation,
                .firesOnRecordDeletion,
                .firesOnRecordUpdate,
            ],
        )
        subscription.notificationInfo = CKSubscription.NotificationInfo(shouldSendContentAvailable: true)
        try await database.save(subscription)
        UserDefaults.standard.setValue(true, forKey: subscriptionID)
    }
    
}
