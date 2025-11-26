//
//  Fields.swift
//  Nuvem
//
//  Created by Mateus Rodrigues on 15/04/26.
//


public struct Fields<Model: CKModel> {
    enum Mode {
        case include
        case exclude
    }
    let mode: Mode
    let fields: [PartialKeyPath<Model>]
}

extension Fields {
    public static func include<each T: CKFieldProtocol>(_ fields: repeat KeyPath<Model, each T>) -> Self {
        var fieldsToInclude = [PartialKeyPath<Model>]()
        for field in repeat each fields {
            fieldsToInclude.append(field)
        }
        return .init(mode: .include, fields: fieldsToInclude)
    }
    public static func exclude<each T: CKFieldProtocol>(_ fields: repeat KeyPath<Model, each T>) -> Self {
        var fieldsToExclude = [PartialKeyPath<Model>]()
        for field in repeat each fields {
            fieldsToExclude.append(field)
        }
        return .init(mode: .exclude, fields: fieldsToExclude)
    }
    public static var all: Self {
        .init(mode: .exclude, fields: [])
    }
    public static var none: Self {
        .init(mode: .include, fields: [])
    }
}

extension Fields {
    var desiredKeys: [String]? {
        switch self.mode {
            case .include:
                if fields.isEmpty {
                    return []
                } else {
                    var desiredKeys: [String] = []
                    desiredKeys.append(contentsOf: fields.map(\.key))
                    return desiredKeys
                }
            case .exclude:
                if fields.isEmpty {
                    return nil
                } else {
                    let fieldKeysToExclude = fields.map { $0.key }
                    let allKeyPaths = Model().allKeyPaths.values
                    var desiredKeys: [String] = []
                    let model = Model()
                    for keyPath in allKeyPaths {
                        if let _field = model[keyPath: keyPath] as? (any _CKFieldProtocol), !fieldKeysToExclude.contains(_field.key) {
                            desiredKeys.append(_field.key)
                        }
                    }
                    return desiredKeys
                }
        }
    }
}

//@_disfavoredOverload
//public func field<each T: CKFieldProtocol>(exclude fields: repeat KeyPath<Model, each T>) -> Self {
//    desiredKeysBuilder.add()
//    var fieldsToExclude = [PartialKeyPath<Model>]()
//    for field in repeat each fields {
//        fieldsToExclude.append(field)
//    }
//    let fieldKeysToExclude = fieldsToExclude.map { $0.key }
//    let allKeyPaths = Model().allKeyPaths.values
//    for keyPath in allKeyPaths {
//        if let _field = Model()[keyPath: keyPath] as? (any _CKFieldProtocol), !fieldKeysToExclude.contains(_field.key) {
//            desiredKeysBuilder.add(keyPath)
//        }
//    }
//    return self
//}
