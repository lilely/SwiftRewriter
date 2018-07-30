import XCTest
import SwiftAST

class Expression_MatcherTests: XCTestCase {
    
    func testMatchCall() {
        let matchTypeNew = Expression.matcher(ident("Type").call("new"))
        
        XCTAssert(matchTypeNew.matches(Expression.identifier("Type").dot("new").call()))
        XCTAssertFalse(matchTypeNew.matches(Expression.identifier("Type").dot("new")))
        XCTAssertFalse(matchTypeNew.matches(Expression.identifier("Type").call()))
    }
    
    func testMatchInvertedPostfix() {
        let sut = Expression.matcher(
            ValueMatcher<PostfixExpression>()
                .inverted { inverted in
                    inverted
                        .atIndex(0, equals: .root(.identifier("test")))
                        .atIndex(2, matcher: .keyPath(\.postfix?.asMember?.name, .differentThan("thing")))
                }
            ).anyExpression()
        
        XCTAssert(sut.matches(Expression.identifier("test").dot("abc").dot("thin")))
        XCTAssertFalse(sut.matches(Expression.constant(0)))
        XCTAssertFalse(sut.matches(Expression.identifier("test")))
        XCTAssertFalse(sut.matches(Expression.identifier("test").dot("abc").dot("thing")))
        
    }
    
    func testMatchInvertedPostfixPostfixAccess() {
        let sut = Expression.matcher(
            ValueMatcher<PostfixExpression>()
                .inverted { inverted in
                    inverted
                        .atIndex(1, matcher: .isMemberAccess)
                        .atIndex(2, matcher: .isSubscription)
                        .atIndex(3, matcher: .isFunctionCall)
                }
            ).anyExpression()
        
        // a.b[0]()
        XCTAssert(
            sut.matches(
                Expression.identifier("a").dot("b").sub(.constant(0)).call()
            )
        )
        // a.b
        XCTAssertFalse(
            sut.matches(
                Expression.identifier("a").dot("b")
            )
        )
        // a[b][0]()
        XCTAssertFalse(
            sut.matches(
                Expression.identifier("a").sub(.identifier("b")).sub(.constant(0)).call()
            )
        )
        // a.b[0].c
        XCTAssertFalse(
            sut.matches(
                Expression.identifier("a").sub(.identifier("b")).sub(.constant(0)).dot("c")
            )
        )
        
    }
    
}