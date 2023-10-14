import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

import MacroImplementation

let macros: [String: Macro.Type] = [
    "CKModel": CKModelMacro.self,
    "CKReferenceField": CKReferenceFieldMacro.self,
]

final class MacrosTests: XCTestCase {
    
    func testCKModel1() throws {
        assertMacroExpansion(
            """
            @CKModel
            struct M2 {
            }
            """,
            expandedSource:
            """
            struct M2 {
            
                public static var recordType: CKRecord.RecordType {
                    "M2"
                }
            
                var record: CKRecord!
            
                @CKTimestamp(.creation)
                var creationDate: Date?
            
                @CKTimestamp(.modification)
                var modificationDate: Date?
            
                init() {
                }
            }

            extension M2: CKModel {
            }
            """,
            macros: macros
        )
    }
    
    func testCKModel2() throws {
        assertMacroExpansion(
            """
            @CKModel
            struct M1 {
               
                var f1: Int
                
                @CKReferenceField
                var f2: M2?
                
                @CKReferenceField("_f3")
                var f3: M2?
                
                @CKReferenceField
                var f4: [M2]?
                
                @CKReferenceField("_f5")
                var f5: [M2]?
                
            }
            """,
            expandedSource:
            """
            struct M1 {
                @CKField("f1")
               
                var f1: Int
                @CKReferenceField.One("f2")
                
                var f2: M2?
                @CKReferenceField.One("_f3")
                
                var f3: M2?
                @CKReferenceField.Many("f4")
                
                var f4: [M2]?
                @CKReferenceField.Many("_f5")
                
                var f5: [M2]?
            
                public static var recordType: CKRecord.RecordType {
                    "M1"
                }
            
                var record: CKRecord!
            
                @CKTimestamp(.creation)
                var creationDate: Date?
            
                @CKTimestamp(.modification)
                var modificationDate: Date?
            
                init() {
                }
            
                init(f1: Int, f2: M2?, f3: M2?, f4: [M2]?, f5: [M2]?) {
                    self.f1 = f1
                    self.f2 = f2
                    self.f3 = f3
                    self.f4 = f4
                    self.f5 = f5
                }
                
            }
            
            extension M1: CKModel {
            }
            """,
            macros: macros
        )
    }
    
}
