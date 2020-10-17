import XCTest
@testable import WebsocketKit

final class WebsocketKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(WebsocketKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
