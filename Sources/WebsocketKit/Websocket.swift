//
//  File.swift
//  
//
//  Created by Alexander Weiß on 17.10.20.
//

import Foundation
import Network

/// Defines a delegate for a websocket connection.
public protocol WebSocketConnectionDelegate: AnyObject {
    func webSocketDidConnect(connection: WebSocketConnection)
    func websocketDidPrepare(connection: WebSocketConnection)
    func webSocketDidDisconnect(connection: WebSocketConnection, closeCode: NWProtocolWebSocket.CloseCode, reason: Data?)
    func websocketDidCancel(connection: WebSocketConnection)
    func webSocketDidReceiveError(connection: WebSocketConnection, error: Error)
    func webSocketDidReceivePong(connection: WebSocketConnection)
    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String)
    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data)
}

/// Websocket representaton
public class Websocket {

    // MARK: - Public properties
    weak public var delegate: WebSocketConnectionDelegate?

    // MARK: - Private properties
    private let connection: NWConnection
    private let endpoint: NWEndpoint
    private let parameters: NWParameters
    private let queue: DispatchQueue

    private let autoReplyToPing: Bool

    private var pingTimer: Timer?

    // MARK: - Initialization
    
    /// Initialize a new websocket instance
    /// - Parameters:
    ///   - url: Websocket url to connect to
    ///   - autoReplyToPing: Flag to indicate whether the instance should auto reply to ping messages
    ///   - connectionQueue: Queue on with the messages should be handled
    ///   - additionalHeaders: Additional HTTP header to include when connect to the server
    public init(url: URL,
         autoReplyToPing: Bool = false,
         connectionQueue: DispatchQueue = .global(qos: .default),
         additionalHeaders: [String: String]? = [:]
    ) {

        endpoint = .url(url)
        parameters = url.scheme == "ws" ? .tcp : .tls

        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = autoReplyToPing
        wsOptions.setAdditionalHeaders(additionalHeaders?.map { ($0.key, $0.value) } ?? [] )
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)

        connection = NWConnection(to: endpoint, using: parameters)

        self.queue = connectionQueue
        self.autoReplyToPing = autoReplyToPing
    }

    public convenience init(request: URLRequest) {
        self.init(url: request.url!, additionalHeaders: request.allHTTPHeaderFields)
    }


    // MARK: - Suplementary methods

    /// Listen to incoming messages from the websocket
    private func listen() {
        connection.receiveMessage { [weak self] (data, context, _, error) in
            guard let self = self else {
                return
            }

            if let data = data, !data.isEmpty, let context = context {
                self.handleMessage(data: data, context: context)
            }

            if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.listen()
            }
        }
    }

    /// Handle received websocket message
    ///
    /// - Parameters:
    ///   - data: Received data
    ///   - context: Content context
    private func handleMessage(data: Data, context: NWConnection.ContentContext) {
        guard let metadata = context.protocolMetadata.first as? NWProtocolWebSocket.Metadata else {
            return
        }

        switch metadata.opcode {
        case .binary:
            self.delegate?.webSocketDidReceiveMessage(connection: self, data: data)
        case .cont:
            break
        case .text:
            guard let string = String(data: data, encoding: .utf8) else {
                return
            }
            self.delegate?.webSocketDidReceiveMessage(connection: self, string: string)
        case .close:
            connectionDidClose(closeCode: metadata.closeCode, reason: data)
        case .ping:
            // SEE `autoReplyPing = true` in `init()`.
            break
        case .pong:
            // SEE `ping()` FOR PONG RECEIVE LOGIC.
            break
        @unknown default:
            fatalError()
        }
    }


    /// Send `Data` over the websocket connection
    ///
    /// - Parameters:
    ///   - data: Data to be send
    ///   - context: Content context
    private func send(data: Data?, context: NWConnection.ContentContext) {
        connection.send(content: data,
                        contentContext: context,
                        isComplete: true,
                        completion: .contentProcessed({ [weak self] error in
                            guard let self = self else {
                                return
                            }

                            if let error = error {
                                self.connectionDidFail(error: error)
                            }
                        }))
    }

    /// Handle connection failure
    ///
    /// - Parameters:
    ///     - error: Occured error
    private func connectionDidFail(error: NWError) {
        delegate?.webSocketDidReceiveError(connection: self, error: error)
        stop()
    }

    /// Handle state changes in the websocket connection
    ///
    /// - Parameters:
    ///     - state: New connection state
    private func connectionStateDidChange(to state: NWConnection.State) {
        switch state {
        case .setup:
            // The initial state prior to start
            break
        case .preparing:
            delegate?.websocketDidPrepare(connection: self)
        case .waiting(let error), .failed(let error):
            connectionDidFail(error: error)
        case .ready:
            // When the connection is ready we start to listen
            listen()
            delegate?.webSocketDidConnect(connection: self)
        case .cancelled:
            delegate?.websocketDidCancel(connection: self)
        @unknown default:
            fatalError()
        }
    }

    /// Handle connection close event
    ///
    /// - Parameters:
    ///   - closeCode: Code of the close event
    ///   - reason: Reason why the connection was closed
    private func connectionDidClose(closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        delegate?.webSocketDidDisconnect(connection: self, closeCode: closeCode, reason: reason)
        stop()
    }

    /// Stop and cancel the websocket connection
    private func stop() {
        connection.stateUpdateHandler = nil
        connection.cancel()
    }
}

// MARK: - WebSocketConnection
extension Websocket: WebSocketConnection {
    
    public func connect() {
        connection.stateUpdateHandler = connectionStateDidChange(to:)
        connection.start(queue: queue)
    }

    public func send(string: String) {
        guard let data = string.data(using: .utf8) else {
            return
        }

        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "textContext", metadata: [metadata])

        send(data: data, context: context)
    }

    public func send(data: Data) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .binary)
        let context = NWConnection.ContentContext(identifier: "binaryContext", metadata: [metadata])

        send(data: data, context: context)
    }

    public func ping(interval: TimeInterval) {
        pingTimer = .scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.ping()
        }
    }

    public func ping() {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .ping)
        metadata.setPongHandler(queue) { [weak self] error in
            guard let self = self else {
                return
            }

            if let error = error {
                self.connectionDidFail(error: error)
            }
            self.delegate?.webSocketDidReceivePong(connection: self)

        }

        let context = NWConnection.ContentContext(identifier: "pingContext", metadata: [metadata])
        send(data: Data(), context: context)
    }

    public func disconnect(closeCode: NWProtocolWebSocket.CloseCode = .protocolCode(.normalClosure)) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .close)
        metadata.closeCode = closeCode
        let context = NWConnection.ContentContext(identifier: "textContext", metadata: [metadata])

        send(data: nil, context: context)
        connectionDidClose(closeCode: closeCode, reason: nil)
        pingTimer?.invalidate()
    }
}

