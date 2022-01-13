@testable import SSDPClient
import XCTest

let duration: TimeInterval = 5

// MARK: - SSDPDiscoveryTests

class SSDPDiscoveryTests: XCTestCase {
    static var allTests = [
        ("testDiscoverService", testDiscoverService),
        ("testStop", testStop),
    ]

    let client = SSDPDiscovery()

    var discoverServiceExpectation: XCTestExpectation?
    var startExpectation: XCTestExpectation?
    var stopExpectation: XCTestExpectation?
    var errorExpectation: XCTestExpectation?

    override func setUp() {
        super.setUp()

        errorExpectation = expectation(description: "Error")
        errorExpectation!.isInverted = true
        client.delegate = self
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDiscoverService() {
        startExpectation = expectation(description: "Start")
        discoverServiceExpectation = expectation(description: "DiscoverService")

        client.discoverService(forDuration: duration, searchTarget: "ssdp:all", port: 1900)

        wait(for: [errorExpectation!, startExpectation!, discoverServiceExpectation!], timeout: duration)
    }

    func testStop() {
        stopExpectation = expectation(description: "Stop")
        client.discoverService()
        client.stop()
        wait(for: [errorExpectation!, stopExpectation!], timeout: duration)
    }
}

// MARK: SSDPDiscoveryDelegate

extension SSDPDiscoveryTests: SSDPDiscoveryDelegate {
    func ssdpDiscovery(_ discovery: SSDPDiscovery, didDiscoverService service: SSDPService) {
        discoverServiceExpectation?.fulfill()
        discoverServiceExpectation = nil
    }

    func ssdpDiscoveryDidStart(_ discovery: SSDPDiscovery) {
        startExpectation?.fulfill()
    }

    func ssdpDiscoveryDidFinish(_ discovery: SSDPDiscovery) {
        stopExpectation?.fulfill()
    }

    func ssdpDiscovery(_ discovery: SSDPDiscovery, didFinishWithError error: Error) {
        errorExpectation?.fulfill()
    }
}
