import CloudKit

public protocol CKAssetFieldValue {
    
    static func get(_ value: Data) -> Self?
    static func set(_ value: Self?) -> Data?
    
}

extension Optional: CKAssetFieldValue where Wrapped: CKAssetFieldValue {
    
    public static func get(_ value: Data) -> Self? {
        return Wrapped.get(value)
    }
    
    public static func set(_ value: Self?) -> Data? {
        return Wrapped.set(value as? Wrapped)
    }

}

extension Data: CKAssetFieldValue {
    
    public static func get(_ value: Data) -> Data? {
        return value
    }
    
    public static func set(_ value: Data?) -> Data? {
        return value
    }
    
}

#if canImport(UIKit)

import UIKit

extension UIImage: CKAssetFieldValue {
    
    public static func get(_ recordValue: Data) -> Self? {
        return Self(data: recordValue)
    }
    
    public static func set(_ recordValue: UIImage?) -> Data? {
        return recordValue?.pngData()
    }
    
}


#endif

#if canImport(AppKit)

import AppKit

extension NSImage: CKAssetFieldValue {
    
    public static func get(_ recordValue: Data) -> Self? {
        return Self(data: recordValue)
    }
    
    public static func set(_ value: NSImage?) -> Data? {
        return value?.tiffRepresentation
    }
    
}


#endif

extension CIImage: CKAssetFieldValue {
    
    public static func get(_ recordValue: Data) -> Self? {
        return Self(data: recordValue)
    }
    
    public static func set(_ value: CIImage?) -> Data? {
        let context = CIContext()
        guard let value else {
            return nil
        }
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }
        return try? context.pngRepresentation(
            of: value,
            format: .RGBA8,
            colorSpace: colorSpace,
            options: [:]
        )
    }
    
}

extension CGImage: CKAssetFieldValue {
    
    public static func get(_ recordValue: Data) -> Self? {
        guard let ciImage = CIImage.get(recordValue) else {
            return nil
        }
        let context = CIContext(options: nil)
        return context.createCGImage(ciImage, from: ciImage.extent) as? Self
    }
    
    public static func set(_ value: CGImage?) -> Data? {
        guard let value else {
            return nil
        }
        var ciImage = CIImage(cgImage: value)
        return CIImage.set(ciImage)
    }
    
}
