# WebSocketKit

<p align="center">
    <a href="https://developer.apple.com/swift/">
      <img src="https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat" alt="Swift 5.0">
   </a>
   <a href="https://github.com/apple/swift-package-manager">
      <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="SPM">
   </a>

   <a href="https://github.com/alexanderwe/LoggingKit">
      <img src="https://github.com/alexanderwe/WebSocketKit/workflows/Main%20Branch%20CI/badge.svg" alt="CI">
   </a>
   <!-- <a href="https://codecov.io/gh/alexanderwe/WebSocketKit">
        <img src="https://codecov.io/gh/alexanderwe/WebSocketKit/branch/main/graph/badge.svg?token=zNmgmMp5zB" alt="Code coverage">
   </a> -->
</p>

<p align="center">
    WebSocketKit is a small wrapper around the `Network` framework to work with websocket connections
</p>

## Installation

### Swift Package Manager

To integrate using Apple's [Swift Package Manager](https://swift.org/package-manager/), add the following as a dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/alexanderwe/WebSocketKit.git", from: "1.0.0")
]
```

Alternatively navigate to your Xcode project, select `Swift Packages` and click the `+` icon to search for `WebSocketKit`.

### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate `WebSocketKit` into your project manually. Simply drag the `Sources` Folder into your Xcode project.

## Usage

At first import `WebSocketKit`

```swift
import WebSocketKit
```

Define a `WebsSocket` instance

```swift
let websocket = WebsSocket(url: URL(string: "wss://echo.websocket.org")!)
```

It also makes sense to create a instance of a class that conforms to the `WebSocketConnectionDelegate` in order to receive websocket events. Be aware that you also need to import the `Network` framework in order to have access to `NWProtocolWebSocket`.

```swift
import Network


class WebSocketDelegate: WebSocketConnectionDelegate {

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
        print("WebSocket did receive error: \(error)")
    }

    func webSocketDidReceivePong(connection: WebSocketConnection) {
        print("WebSocket did receive pong")
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        print("WebSocket did receive string message: \(string)")
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        print("WebSocket did receive data message")
    }
}
```

Set an instance of the delegate instance to the `Websocket` instance and start listening for events

```swift
let delegate = WebSocketDelegate()
websocket.delegate = delegate

websocket.connect() // Connects to the url specified in the initializer and listens for messages
```

### Custom headers

Often it is necessary to attach custom headers to the connection. You can do so by specifying them in the initializer of the `Websocket` class.

```swift
let websocket = Websocket(url: URL(string: "wss://echo.websocket.org")!,
                          additionalHeaders: [
                            "Authorization:": "Bearer <someToken>",
                            "My-Custom-Header-Key:": "My-Custom-Header-Value"
                          ]
)
```

## Contributing

Contributions are very welcome 🙌
