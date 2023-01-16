import CloudKit

public protocol CKFieldProtocol: AnyObject {
    var key: String { get }
    var record: CKRecord! { get set }
}
