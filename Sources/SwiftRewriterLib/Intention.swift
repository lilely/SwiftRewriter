import GrammarModels

/// An intention represents the intent of the code transpiler to generate a
/// file/class/struct/property/etc. with Swift code.
public protocol Intention: class, Context {
    /// Reference to an AST node that originated this source-code generation
    /// intention
    var source: ASTNode? { get }
    
    /// Parent for this intention
    var parent: Intention? { get }
}

/// An intention to create a .swift file
public class FileGenerationIntention: Intention {
    /// The intended output file path
    public var filePath: String
    
    /// Gets the types to create on this file.
    private(set) var typeIntentions: [TypeGenerationIntention] = []
    
    /// Gets the typealias intentions to create on this file.
    private(set) var typealiasIntentions: [TypealiasIntention] = []
    
    /// Gets the protocols to create on this file.
    private(set) var protocolIntentions: [ProtocolGenerationIntention] = []
    
    /// Gets the global functions to create on this file.
    private(set) var globalFunctionIntentions: [GlobalFunctionGenerationIntention] = []
    
    /// Gets the global variables to create on this file.
    private(set) var globalVariableIntentions: [GlobalVariableGenerationIntention] = []
    
    public var source: ASTNode?
    
    weak public var parent: Intention?
    
    public init(filePath: String) {
        self.filePath = filePath
    }
    
    public func addType(_ intention: TypeGenerationIntention) {
        typeIntentions.append(intention)
        intention.parent = self
    }
    
    public func addTypealias(_ intention: TypealiasIntention) {
        typealiasIntentions.append(intention)
        intention.parent = self
    }
    
    public func removeTypes(where predicate: (TypeGenerationIntention) -> Bool) {
        for (i, type) in typeIntentions.enumerated().reversed() {
            if predicate(type) {
                type.parent = nil
                typeIntentions.remove(at: i)
            }
        }
    }
    
    public func addProtocol(_ intention: ProtocolGenerationIntention) {
        protocolIntentions.append(intention)
        intention.parent = self
    }
    
    public func addGlobalFunction(_ intention: GlobalFunctionGenerationIntention) {
        globalFunctionIntentions.append(intention)
        intention.parent = self
    }
    
    public func addGlobalVariable(_ intention: GlobalVariableGenerationIntention) {
        globalVariableIntentions.append(intention)
        intention.parent = self
    }
}

/// An intention to generate a global function.
public class GlobalFunctionGenerationIntention: FromSourceIntention {
    
}

/// An intention to generate a global variable.
public class GlobalVariableGenerationIntention: FromSourceIntention, ValueStorageIntention {
    public var variableSource: VariableDeclaration? {
        return source as? VariableDeclaration
    }
    
    public var name: String
    public var storage: ValueStorage
    public var initialValueExpr: GlobalVariableInitialValueIntention?
    
    public init(name: String, storage: ValueStorage, accessLevel: AccessLevel = .internal,
                source: ASTNode? = nil) {
        self.name = name
        self.storage = storage
        super.init(accessLevel: accessLevel, source: source)
    }
}

/// An intention to generate the initial value for a global variable.
public class GlobalVariableInitialValueIntention: FromSourceIntention {
    public var expression: Expression
    
    public init(expression: Expression, source: ASTNode?) {
        self.expression = expression
        
        super.init(accessLevel: .public, source: source)
    }
}

/// Represents an intention that has a value associated that indicates whether it
/// was defined within NS_ASSUME_NONNULL contexts
public protocol NonNullScopedIntention: Intention {
    /// Gets a value indicating whether this intention was defined within
    /// NS_ASSUME_NONNULL contexts
    var inNonnullContext: Bool { get }
}

/// Defines a protocol for a value storage intention.
public protocol ValueStorageIntention: Intention {
    var name: String { get }
    var storage: ValueStorage { get }
}

public extension ValueStorageIntention {
    public var type: SwiftType {
        return storage.type
    }
    
    public var ownership: Ownership {
        return storage.ownership
    }
    
    public var isConstant: Bool {
        return storage.isConstant
    }
}
