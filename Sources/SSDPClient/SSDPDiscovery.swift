import Foundation
import Socket

private func printerr(_ msg: String, end: String = "\n") {
    fputs("\(msg)\(end)", stderr)
}

// MARK: - SSDPDiscoveryDelegate

/// Delegate for service discovery
public protocol SSDPDiscoveryDelegate {
    /// Tells the delegate a requested service has been discovered.
    func ssdpDiscovery(_ discovery: SSDPDiscovery, didDiscoverService service: SSDPService)

    /// Tells the delegate that the discovery ended due to an error.
    func ssdpDiscovery(_ discovery: SSDPDiscovery, didFinishWithError error: Error)

    /// Tells the delegate that the discovery has started.
    func ssdpDiscoveryDidStart(_ discovery: SSDPDiscovery)

    /// Tells the delegate that the discovery has finished.
    func ssdpDiscoveryDidFinish(_ discovery: SSDPDiscovery)
}

public extension SSDPDiscoveryDelegate {
    func ssdpDiscovery(_ discovery: SSDPDiscovery, didDiscoverService service: SSDPService) {}

    func ssdpDiscovery(_ discovery: SSDPDiscovery, didFinishWithError error: Error) {}

    func ssdpDiscoveryDidStart(_ discovery: SSDPDiscovery) {}

    func ssdpDiscoveryDidFinish(_ discovery: SSDPDiscovery) {}
}

// MARK: - SSDPDiscovery

/// SSDP discovery for UPnP devices on the LAN
public class SSDPDiscovery {
    // MARK: Lifecycle

    // MARK: Initialisation

    public init() {}

    deinit {
        self.stop()
    }

    // MARK: Open

    // MARK: Public functions

    open func discoverService(
        everySeconds seconds: TimeInterval,
        forDuration duration: TimeInterval = 10,
        searchTarget: String = "ssdp:all",
        port: Int32 = 1900
    ) {
        searchInitiator?.invalidate()
        searchInitiator = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [self] t in
            discoverService(forDuration: duration, searchTarget: searchTarget, port: port)
        }
    }

    /**
         Discover SSDP services for a duration.
         - Parameters:
             - duration: The amount of time to wait.
             - searchTarget: The type of the searched service.
     */
    open func discoverService(forDuration duration: TimeInterval = 10, searchTarget: String = "ssdp:all", port: Int32 = 1900) {
        print("Start SSDP discovery for \(Int(duration)) duration...")
        delegate?.ssdpDiscoveryDidStart(self)

        let message = "M-SEARCH * HTTP/1.1\r\n" +
            "MAN: \"ssdp:discover\"\r\n" +
            "HOST: 239.255.255.250:\(port)\r\n" +
            "ST: \(searchTarget)\r\n" +
            "MX: \(Int(duration))\r\n\r\n"

        do {
            socket = try Socket.create(type: .datagram, proto: .udp)
            try socket?.listen(on: 0)

            readResponses(forDuration: duration)

            #if DEBUG
                print("Send: \(message)")
            #endif
            try socket?.write(from: message, to: Socket.createAddress(for: "239.255.255.250", on: port)!)

        } catch {
            printerr("Socket error: \(error)")
            forceStop()
            delegate?.ssdpDiscovery(self, didFinishWithError: error)
        }
    }

    open func stopRecurringSearch() {
        searchInitiator?.invalidate()
        stop()
    }

    /// Stop the discovery before the timeout.
    open func stop() {
        if socket != nil {
            print("Stop SSDP discovery")
            forceStop()
            delegate?.ssdpDiscoveryDidFinish(self)
        }
    }

    // MARK: Public

    /// Delegate for service discovery
    public var delegate: SSDPDiscoveryDelegate?

    /// The client is discovering
    public var isDiscovering: Bool {
        socket != nil
    }

    // MARK: Private

    /// The UDP socket
    private var socket: Socket?

    private var searchInitiator: Timer?

    // MARK: Private functions

    /// Read responses.
    private func readResponses() {
        guard let socket = socket else { return }
        do {
            var data = Data()
            let (bytesRead, address) = try socket.readDatagram(into: &data)

            if bytesRead > 0, let address = address,
               let response = String(data: data, encoding: .utf8),
               let (remoteHost, _) = Socket.hostnameAndPort(from: address)
            {
                #if DEBUG
                    print("Received: \(response) from \(remoteHost)")
                #endif
                delegate?.ssdpDiscovery(self, didDiscoverService: SSDPService(host: remoteHost, response: response))
            }

        } catch {
            printerr("Socket error: \(error)")
            forceStop()
            delegate?.ssdpDiscovery(self, didFinishWithError: error)
        }
    }

    /// Read responses with timeout.
    private func readResponses(forDuration duration: TimeInterval) {
        let queue = DispatchQueue.global()

        queue.async {
            while self.isDiscovering {
                self.readResponses()
            }
        }

        queue.asyncAfter(deadline: .now() + duration) { [unowned self] in
            self.stop()
        }
    }

    /// Force stop discovery closing the socket.
    private func forceStop() {
        if isDiscovering, let socket = socket {
            socket.close()
        }
        socket = nil
    }
}
