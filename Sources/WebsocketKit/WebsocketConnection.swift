//
//  WebSocketConnection.swift
//  
//
//  Created by Alexander Weiß on 17.10.20.
//

import Foundation
import Network


/// Defines a websocket connection.
public protocol WebSocketConnection {
    
    /// Connect to the websocket.
    func connect()
    
    /// Send a UTF-8 formatted `String` over the websocket.
    /// - Parameters:
    ///   - string: The `String` that will be sent.
    func send(string: String)
    
    /// Send some `Data` over the websocket.
    /// - Parameters:
    ///   - data: The `Data` that will be sent.
    func send(data: Data)
    
    /// Ping the websocket once.
    func ping()
    
    /// Disconnect from the websocket.
    /// - Parameters:
    ///   - closeCode: The code to use when closing the websocket connection.
    func disconnect(closeCode: NWProtocolWebSocket.CloseCode)
    
    var delegate: WebSocketConnectionDelegate? { get set }
}
