import XCTest
@testable import ObjcParser
import GrammarModels

class ObjcParser_ObjcClassTests: XCTestCase {
    
    func testParseForwardClassDeclaration() throws {
        let source = """
            @class MyClass;
            """
        let sut = ObjcParser(string: source)
        
        try sut.parse()
        
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClass() throws {
        let source = """
            @interface MyClass
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcInterfaceNode(source: source, parser: sut)
        
        XCTAssertEqual(result.identifier.name, "MyClass")
        XCTAssertNil(result.ivarsList)
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClassKeywords() throws {
        let source = """
            @interface MyClass
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcInterfaceNode(source: source, parser: sut)
        
        let keywords = result.childrenMatching(type: KeywordNode.self)
        XCTAssertEqual(result.identifier.name, "MyClass")
        XCTAssertTrue(keywords.contains { $0.keyword == .atInterface })
        XCTAssertTrue(keywords.contains { $0.keyword == .atEnd })
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClassWithEmptyIVars() throws {
        let source = """
            @interface MyClass
            {
            }
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcInterfaceNode(source: source, parser: sut)
        
        XCTAssertEqual(result.identifier.name, "MyClass")
        XCTAssertNotNil(result.ivarsList)
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClassWithIVars() throws {
        let source = """
            @interface MyClass
            {
                NSString *_myString;
                __weak id _delegate;
            }
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcInterfaceNode(source: source, parser: sut)
        
        XCTAssertEqual(result.identifier.name, "MyClass")
        XCTAssertNotNil(result.ivarsList)
        XCTAssertEqual(result.ivarsList?.ivarDeclarations[0].type?.type, .pointer(.struct("NSString")))
        XCTAssertEqual(result.ivarsList?.ivarDeclarations[0].identifier?.name, "_myString")
        XCTAssertEqual(result.ivarsList?.ivarDeclarations[1].type?.type, ObjcType.specified(specifiers: ["__weak"], .id(protocols: [])))
        XCTAssertEqual(result.ivarsList?.ivarDeclarations[1].identifier?.name, "_delegate")
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClassWithIVarsPublic() throws {
        let source = """
            @interface MyClass
            {
            @private
            @protected
            @package
            @public
                NSString *_myString;
                __weak id _delegate;
            }
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcInterfaceNode(source: source, parser: sut)
        
        XCTAssertEqual(result.identifier.name, "MyClass")
        XCTAssertNotNil(result.ivarsList)
        XCTAssertEqual(result.ivarsList?.ivarDeclarations[0].type?.type, .pointer(.struct("NSString")))
        XCTAssertEqual(result.ivarsList?.ivarDeclarations[0].identifier?.name, "_myString")
        XCTAssertEqual(result.ivarsList?.ivarDeclarations[1].type?.type, ObjcType.specified(specifiers: ["__weak"], .id(protocols: [])))
        XCTAssertEqual(result.ivarsList?.ivarDeclarations[1].identifier?.name, "_delegate")
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClassPropertyImplementation() throws {
        let source = """
            @implementation MyClass
            @synthesize abc;
            @dynamic def, ghi=jlm;
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcImplementationNode(source: source, parser: sut)
        
        let properties = result.childrenMatching(type: PropertyImplementation.self)
        XCTAssertEqual(properties.count, 2)
        XCTAssertEqual(properties[0].kind, .synthesize)
        XCTAssertEqual(properties[0].list.items?[0].propertyName.name, "abc")
        XCTAssertNil(properties[0].list.items?[0].ivarName)
        XCTAssertEqual(properties[1].kind, .dynamic)
        XCTAssertEqual(properties[1].list.items?[0].propertyName.name, "def")
        XCTAssertNil(properties[1].list.items?[0].ivarName)
        XCTAssertEqual(properties[1].list.items?[1].propertyName.name, "ghi")
        XCTAssertEqual(properties[1].list.items?[1].ivarName?.name, "jlm")
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClassWithProperty() throws {
        let source = """
            @interface MyClass
            @property BOOL myProperty1;
            @property NSInteger myProperty2;
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcInterfaceNode(source: source, parser: sut)
        
        let keywordsProp1 = result.properties[0].childrenMatching(type: KeywordNode.self)
        XCTAssertTrue(keywordsProp1.contains { $0.keyword == .atProperty })
        XCTAssertEqual(result.properties[0].type?.type, .struct("BOOL"))
        XCTAssertEqual(result.properties[0].identifier?.name, "myProperty1")
        XCTAssert(result.properties[0].childrenMatching(type: TokenNode.self).contains { $0.token.type == .semicolon })
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClassWithPropertyWithGenericType() throws {
        // Arrange
        let source = """
            @interface MyClass
            @property NSArray<NSString*>* myProperty3;
            @end
            """
        let sut = ObjcParser(string: source)
        
        // Act
        let result = _parseTestObjcInterfaceNode(source: source, parser: sut)
        
        // Assert
        let keywordsProp1 = result.properties[0].childrenMatching(type: KeywordNode.self)
        
        XCTAssertTrue(keywordsProp1.contains { $0.keyword == .atProperty })
        XCTAssertEqual(result.properties[0].type?.type, .pointer(.generic("NSArray", parameters: [.pointer(.struct("NSString"))])))
        XCTAssertEqual(result.properties[0].identifier?.name, "myProperty3")
        XCTAssert(result.properties[0].childrenMatching(type: TokenNode.self).contains { $0.token.type == .semicolon })
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClassWithPropertyWithModifiers() throws {
        let source = """
            @interface MyClass
            @property ( atomic, nonatomic , copy ) BOOL myProperty1;
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcInterfaceNode(source: source, parser: sut)
        
        XCTAssertEqual(result.properties[0].type?.type, .struct("BOOL"))
        XCTAssertEqual(result.properties[0].identifier?.name, "myProperty1")
        XCTAssertNotNil(result.properties[0].attributesList)
        XCTAssertEqual(result.properties[0].attributesList?.keywordAttributes[0], "atomic")
        XCTAssertEqual(result.properties[0].attributesList?.keywordAttributes[1], "nonatomic")
        XCTAssertEqual(result.properties[0].attributesList?.keywordAttributes[2], "copy")
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClassWithSuperclass() throws {
        let source = """
            @interface MyClass : Superclass
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcInterfaceNode(source: source, parser: sut)
        
        XCTAssertEqual(result.superclass?.name, "Superclass")
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClassWithProtocolReferenceList() throws {
        let source = """
            @interface MyClass <MyProtocol1, MyProtocol2>
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcInterfaceNode(source: source, parser: sut)
        
        XCTAssertEqual(result.protocolList?.protocols.count, 2)
        XCTAssertEqual(result.protocolList?.protocols[0].name, "MyProtocol1")
        XCTAssertEqual(result.protocolList?.protocols[1].name, "MyProtocol2")
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClassWithSuperclassProtocolReferenceList() throws {
        let source = """
            @interface MyClass : Superclass <MyProtocol1, MyProtocol2>
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcInterfaceNode(source: source, parser: sut)
        
        XCTAssertEqual(result.superclass?.name, "Superclass")
        XCTAssertEqual(result.protocolList?.protocols.count, 2)
        XCTAssertEqual(result.protocolList?.protocols[0].name, "MyProtocol1")
        XCTAssertEqual(result.protocolList?.protocols[1].name, "MyProtocol2")
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClassProtocolReferenceListRecover1() throws {
        let source = """
            @interface MyClass : Superclass <MyProtocol1, >
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcInterfaceNode(source: source, parser: sut)
        
        let protocolList = result.protocolList!
        XCTAssertEqual(result.superclass?.name, "Superclass")
        XCTAssertEqual(protocolList.protocols.count, 1)
        XCTAssertEqual(protocolList.protocols[0].name, "MyProtocol1")
        XCTAssert(result.childrenMatching(type: KeywordNode.self).contains { $0.keyword == .atInterface })
        XCTAssert(protocolList.childrenMatching(type: TokenNode.self).contains { $0.token.type == .operator(.lessThan) })
        XCTAssert(protocolList.childrenMatching(type: TokenNode.self).contains { $0.token.type == .operator(.greaterThan) })
        XCTAssert(result.childrenMatching(type: KeywordNode.self).contains { $0.keyword == .atEnd })
        XCTAssert(sut.diagnostics.errors.count > 0)
    }
    
    func testParseClassWithInit() throws {
        let source = """
            @interface MyClass
            - (instancetype)initWithThing:(id)thing;
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcInterfaceNode(source: source, parser: sut)
        
        let method = result.methods[0]
        let selector = method.methodSelector?.selector
        
        XCTAssertNil(method.body)
        XCTAssertEqual(selector?.keywordDeclarations?.count, 1)
        XCTAssertEqual(selector?.keywordDeclarations?[0].selector?.name, "initWithThing")
        XCTAssertEqual(selector?.keywordDeclarations?[0].identifier?.name, "thing")
        XCTAssert(method.childrenMatching(type: TokenNode.self).contains { $0.token.type == .semicolon })
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseClassImplementationWithInit() throws {
        let source = """
            @implementation MyClass
            - (instancetype)initWithThing:(id)thing {
                [self thing];
            }
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcImplementationNode(source: source, parser: sut)
        
        let method = result.methods[0]
        let selector = method.methodSelector?.selector
        
        XCTAssertNotNil(method.body)
        XCTAssertEqual(selector?.keywordDeclarations?.count, 1)
        XCTAssertEqual(selector?.keywordDeclarations?[0].selector?.name, "initWithThing")
        XCTAssertEqual(selector?.keywordDeclarations?[0].identifier?.name, "thing")
        XCTAssert(method.childrenMatching(type: TokenNode.self).contains { $0.token.type == .openBrace })
        XCTAssert(method.childrenMatching(type: TokenNode.self).contains { $0.token.type == .closeBrace })
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseCategory() throws {
        let source = """
            @interface MyClass ()
            - (void)someMethod;
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestObjcCategoryNode(source: source, parser: sut)
        
        XCTAssertEqual(result.identifier.name, "MyClass")
        XCTAssertNil(result.ivarsList)
        XCTAssertEqual(sut.diagnostics.errors.count, 0, sut.diagnostics.errors.description)
    }
    
    func testParseProtocolReferenceList() throws {
        // Arrange
        let source = "<UITableViewDataSource, UITableViewDelegate, _MyProtocol1_>"
        let sut = ObjcParser(string: source)
        
        // Act
        let root: GlobalContextNode =
            try sut.withTemporaryContext {
                try sut.parseProtocolReferenceList()
            }
        
        // Assert
        let result: ProtocolReferenceList! = root.childrenMatching().first
        
        XCTAssertEqual(result.protocols.count, 3)
        XCTAssertEqual(result.protocols[0].name, "UITableViewDataSource")
        XCTAssertEqual(result.protocols[1].name, "UITableViewDelegate")
        XCTAssertEqual(result.protocols[2].name, "_MyProtocol1_")
    }
    
    func testParseProtocolReferenceListRecovery() throws {
        // Arrange
        let source = "<UITableViewDataSource, ,>"
        let sut = ObjcParser(string: source)
        
        // Act
        let root: GlobalContextNode =
            try sut.withTemporaryContext {
                try sut.parseProtocolReferenceList()
            }
        
        // Assert
        let result: ProtocolReferenceList! = root.childrenMatching().first
        
        XCTAssertEqual(result.protocols.count, 1)
        XCTAssertEqual(result.protocols[0].name, "UITableViewDataSource")
        XCTAssert(sut.diagnostics.errors.count > 0)
    }
    
    private func _parseTestObjcInterfaceNode(source: String, parser: ObjcParser, file: String = #file, line: Int = #line) -> ObjcClassInterface {
        do {
            let root: GlobalContextNode =
                try parser.withTemporaryContext {
                    try parser.parseClassInerfaceNode()
                }
            
            let node: ObjcClassInterface? = root.firstChild()
            return node!
        } catch {
            recordFailure(withDescription: "Failed to parse test '\(source)': \(error)", inFile: #file, atLine: line, expected: false)
            fatalError()
        }
    }
    
    private func _parseTestObjcImplementationNode(source: String, parser: ObjcParser, file: String = #file, line: Int = #line) -> ObjcClassImplementation {
        do {
            let root: GlobalContextNode =
                try parser.withTemporaryContext {
                    try parser.parseClassImplementation()
            }
            
            let node: ObjcClassImplementation? = root.firstChild()
            return node!
        } catch {
            recordFailure(withDescription: "Failed to parse test '\(source)': \(error)", inFile: #file, atLine: line, expected: false)
            fatalError()
        }
    }
    
    private func _parseTestObjcCategoryNode(source: String, parser: ObjcParser, file: String = #file, line: Int = #line) -> ObjcClassCategory {
        do {
            let root: GlobalContextNode =
                try parser.withTemporaryContext {
                    try parser.parseClassCategoryNode()
            }
            
            let node: ObjcClassCategory? = root.firstChild()
            return node!
        } catch {
            recordFailure(withDescription: "Failed to parse test '\(source)': \(error)", inFile: #file, atLine: line, expected: false)
            fatalError()
        }
    }
}
