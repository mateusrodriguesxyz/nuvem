import CloudKit

public protocol CKFieldValue {
        
    static func get(_ value: CKRecordValue?) -> Self?
    static func set(_ value: Self?) -> CKRecordValue?
    
}

public protocol CKCodable: Codable, CKFieldValue { }

extension CKCodable {
    public static func get(_ value: (any CKRecordValue)?) -> Self? {
        do {
            guard let data = (value as? String)?.data(using: .utf8) else {
                return nil
            }
            return try JSONDecoder().decode(Self.self, from: data)
        } catch {
            print(error)
            return nil
        }
    }
    public static func set(_ value: Self?) -> (any CKRecordValue)? {
        do {
            let data = try JSONEncoder().encode(value)
            return String(data: data, encoding: .utf8) as? CKRecordValue
        } catch {
            print(error)
            return nil
        }
    }
}

extension CKFieldValue where Self: CKRecordValueProtocol {
    
    public static func get(_ value: CKRecordValue?) -> Self? {
        return value as? Self
    }
    
    public static func set(_ value: Self?) -> CKRecordValue? {
        return value as? CKRecordValue
    }
    
}

extension CKFieldValue where Self: RawRepresentable {
    
    public static func get(_ value: CKRecordValue?) -> Self? {
        if let rawValue = value as? RawValue {
            return Self(rawValue: rawValue)
        } else {
            return nil
        }
    }
    
    public static func set(_ value: Self?) -> CKRecordValue? {
        return value?.rawValue as? CKRecordValue
    }
    
}

extension Int: CKFieldValue { }

extension Double: CKFieldValue { }

extension String: CKFieldValue { }

extension Bool: CKFieldValue { }

extension Date: CKFieldValue { }

extension Optional: CKFieldValue where Wrapped: CKFieldValue {

    public static func get(_ value: CKRecordValue?) -> Self? {
        return Wrapped.get(value)
    }

    public static func set(_ value: Self?) -> CKRecordValue? {
        return Wrapped.set(value?.flatMap(\.self))
    }

}

extension Array: CKFieldValue where Element: CKRecordValueProtocol {
    
    public static func get(_ value: CKRecordValue?) -> Self? {
        return value as? Self
    }
    
    public static func set(_ value: Self?) -> CKRecordValue? {
        return value as? CKRecordValue
    }
    
}

