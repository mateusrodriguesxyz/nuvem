//import Foundation
//
//protocol CKExpressible {
//    func parse() -> String
//    func parseAsExpression() -> String
//}
//
//extension CKExpressible {
//    func parseAsExpression() -> String { parse() }
//}
//
//@available(macOS 14, *)
//extension PredicateExpressions.KeyPath: CKExpressible where Root.Output: CKModel2 {
//    func parse() -> String {
//        let key = Root.Output.fields[self.keyPath, default: ""]
//        switch Output.self {
//        case is Bool.Type :
//            return "\(key) == 1"
//        default:
//            return key
//        }
//    }
//    func parseAsExpression() -> String {
//        let key = Root.Output.fields[self.keyPath, default: ""]
//        return key
//    }
//}
//
//@available(macOS 14, *)
//extension PredicateExpressions.Value: CKExpressible where Output: AttributeValueProtocol {
//    func parse() -> String {
//        switch Output.self {
//        case is String.Type :
//            return "\"\(value)\""
//        case is Bool.Type :
//            return "\(NSNumber(booleanLiteral: value as! Bool))"
//        default:
//            return ""
//        }
//    }
//}
//
//@available(macOS 14, *)
//extension PredicateExpressions.Equal: CKExpressible where LHS: CKExpressible, RHS: CKExpressible {
//    func parse() -> String {
//        return "\(lhs.parseAsExpression()) == \(rhs.parseAsExpression())"
//    }
//}
//
//@available(macOS 14, *)
//extension PredicateExpressions.Conjunction: CKExpressible where LHS: CKExpressible, RHS: CKExpressible {
//    func parse() -> String {
//        return "\(lhs.parse()) AND \(rhs.parse())"
//    }
//}
//
//@available(macOS 14, *)
//extension PredicateExpressions.Disjunction: CKExpressible where LHS: CKExpressible, RHS: CKExpressible {
//    func parse() -> String {
//        return "\(lhs.parse()) OR \(rhs.parse())"
//    }
//}
//
//
//@available(macOS 14, *)
//extension PredicateExpressions.Variable: CKExpressible {
//    func parse() -> String {
//        return "" // Usually ignored in SQL generation as columns imply the table
//    }
//}
//
//import Playgrounds
//import CloudKit
//
//protocol CKModel2: CKModel {
//    static var fields: [PartialKeyPath<Self>: String] { get }
//}
//
//struct Todo: CKModel2 {
//    
//    static var fields: [PartialKeyPath<Todo> : String] = [
//        \Todo.text : "text",
//        \Todo.isDone : "isDone",
//    ]
//
//    var record: CKRecord!
//    
//    @CKField("text", default: "")
//    var text: String
//    
//    @CKField("isDone", default: false)
//    var isDone: Bool
//    
//    init() { }
//}
//
//class M: NSObject {
//    @objc var value1: String = ""
//    @objc var value2: Bool = false
//}
//
//#Playground {
//    
//    if #available(macOS 14, *) {
//        let p = #Predicate<M> { $0.value1 == "A" || $0.value2 }
//        print(NSPredicate(p))
//    } else {
//        // Fallback on earlier versions
//    }
//    
////    let todo = Todo()
////    
////    let filter = \Todo.$isDone == true && \Todo.$text == "hello"
////    
////    print(filter.predicate)
////
//    if #available(macOS 14, *) {
//        let predicate = #Predicate<Todo> { $0.isDone }
//        let expression = predicate.expression as? CKExpressible
//        if let expression {
//            print("\(expression.parse())")
//        } else {
//            print("nil")
//        }
//    }
//}
//
