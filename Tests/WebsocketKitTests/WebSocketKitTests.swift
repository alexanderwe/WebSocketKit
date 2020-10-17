import XCTest
import Network
@testable import WebSocketKit

class WebSocketTestDelegate: WebSocketConnectionDelegate {
    
    var asyncExpectation: XCTestExpectation?
    
    func webSocketDidConnect(connection: WebSocketConnection) {
        print("WebSocket did connect")
    }
    
    func websocketDidPrepare(connection: WebSocketConnection) {
        print("WebSocket did prepare")
    }
    
    func webSocketDidDisconnect(connection: WebSocketConnection, closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        print("WebSocket did disconnect")
    }
    
    func websocketDidCancel(connection: WebSocketConnection) {
        print("WebSocket did cancel")
    }
    
    func webSocketDidReceiveError(connection: WebSocketConnection, error: Error) {
        print("WebSocket did receive error \(error)")
    }
    
    func webSocketDidReceivePong(connection: WebSocketConnection) {
        print("WebSocket did receive pong")
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        guard let expectation = asyncExpectation else {
            XCTFail("WebSocketTestDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        print("WebSocket did receive string message")
        expectation.fulfill()
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        guard let expectation = asyncExpectation else {
            XCTFail("WebSocketTestDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        print("WebSocket did receive data message")
        expectation.fulfill()
    }
}


final class WebSocketKitTests: XCTestCase {
    
    final let testUrl = URL(string: "wss://echo.WebSocket.org")!
    
    func testSendStringMessage() {
        let websocket = WebSocket(url: testUrl)
        
        let expectation = XCTestExpectation(description: "Receive a message from the remote server")
        
        let delegate = WebSocketTestDelegate()
        delegate.asyncExpectation = expectation
        
        websocket.delegate = delegate
        websocket.connect()
        websocket.send(string: "Test")
       
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testSendDataMessage() {
        let websocket = WebSocket(url: testUrl)
        
        let expectation = XCTestExpectation(description: "Receive a message from the remote server")
        
        let delegate = WebSocketTestDelegate()
        delegate.asyncExpectation = expectation
        
        websocket.delegate = delegate
        websocket.connect()
        websocket.send(data: "Test".data(using: .utf8)!)
       
        wait(for: [expectation], timeout: 10.0)
    }

    static var allTests = [
        ("testSendStringMessage", testSendStringMessage),
        ("testSendDataMessage", testSendDataMessage)
    ]
}
