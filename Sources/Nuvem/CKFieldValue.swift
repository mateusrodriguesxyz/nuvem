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

private protocol _JSONCodableArray {
    static func _decodeJSON(from data: Data) -> Any?
    static func _encodeJSON(_ value: Any) -> (any CKRecordValue)?
}

extension Array: _JSONCodableArray where Element: CKCodable {
    static func _decodeJSON(from data: Data) -> Any? {
        try? JSONDecoder().decode(Self.self, from: data)
    }
    static func _encodeJSON(_ value: Any) -> (any CKRecordValue)? {
        guard let array = value as? Self, let data = try? JSONEncoder().encode(array) else { return nil }
        return String(data: data, encoding: .utf8) as? CKRecordValue
    }
}

extension Array: CKFieldValue where Element: CKFieldValue {
    
    public static func get(_ value: (any CKRecordValue)?) -> Array<Element>? {
        if let result = value as? Self {
            return result
        }
        if let json = value as? String, let data = json.data(using: .utf8), let decoded = (Self.self as? any _JSONCodableArray.Type)?._decodeJSON(from: data) as? Self {
            return decoded
        }
        return nil
    }
    
    public static func set(_ value: Array<Element>?) -> (any CKRecordValue)? {
        guard let value else { return nil }
        if let encoded = (Self.self as? any _JSONCodableArray.Type)?._encodeJSON(value) {
            return encoded
        }
        return value as CKRecordValue
    }
    
    public static func get(_ value: (any CKRecordValue)?) -> Self? where Element: RawRepresentable, Element.RawValue: CKRecordValueProtocol {
        guard let rawValues = value as? [Element.RawValue] else { return nil }
        return rawValues.compactMap(Element.init)
    }
    
    public static func set(_ value: Self?) -> (any CKRecordValue)? where Element: RawRepresentable, Element.RawValue: CKRecordValueProtocol {
        value?.map(\.rawValue) as? CKRecordValue
    }
    
}

