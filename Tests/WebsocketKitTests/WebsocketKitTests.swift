import XCTest
import Network
@testable import WebsocketKit

class WebsocketTestDelegate: WebSocketConnectionDelegate {
    
    var asyncExpectation: XCTestExpectation?
    
    func webSocketDidConnect(connection: WebSocketConnection) {
        print("Websocket did connect")
    }
    
    func websocketDidPrepare(connection: WebSocketConnection) {
        print("Websocket did prepare")
    }
    
    func webSocketDidDisconnect(connection: WebSocketConnection, closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        print("Websocket did disconnect")
    }
    
    func websocketDidCancel(connection: WebSocketConnection) {
        print("Websocket did cancel")
    }
    
    func webSocketDidReceiveError(connection: WebSocketConnection, error: Error) {
        print("Websocket did receive error")
    }
    
    func webSocketDidReceivePong(connection: WebSocketConnection) {
        print("Websocket did receive pong")
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        guard let expectation = asyncExpectation else {
            XCTFail("WebsocketTestDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        print("Websocket did receive string message")
        expectation.fulfill()
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        guard let expectation = asyncExpectation else {
            XCTFail("WebsocketTestDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        print("Websocket did receive data message")
        expectation.fulfill()
    }
}


final class WebsocketKitTests: XCTestCase {
    
    final let testUrl = URL(string: "wss://echo.websocket.org")!
    
    func testSendStringMessage() {
        let websocket = Websocket(url: testUrl)
        
        let expectation = XCTestExpectation(description: "Receive a message from the remote server")
        
        let delegate = WebsocketTestDelegate()
        delegate.asyncExpectation = expectation
        
        websocket.delegate = delegate
        websocket.connect()
        websocket.send(string: "Test")
       
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testSendDataMessage() {
        let websocket = Websocket(url: testUrl)
        
        let expectation = XCTestExpectation(description: "Receive a message from the remote server")
        
        let delegate = WebsocketTestDelegate()
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
