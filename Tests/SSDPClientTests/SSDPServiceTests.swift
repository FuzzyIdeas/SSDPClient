import XCTest

@testable import SSDPClient

let response = "HTTP/1.1 200 OK\r\n" +
    "CACHE-CONTROL: max-age=120\r\n" +
    "ST: upnp:rootdevice\r\n" +
    "USN: uuid:111111111-2222-3333-4444-000000000000::upnp:rootdevice\r\n" +
    "EXT:\r\n" +
    "SERVER: system/system UPnP/1.1 MiniUPnPd/1.8\r\n" +
    "LOCATION: http://192.168.1.1:10000/root.xml\r\n" +
    "OPT: \"http://schemas.upnp.org/upnp/1/0/\"; ns=01\r\n\r\n"

// MARK: - SSDPServiceTests

class SSDPServiceTests: XCTestCase {
    static var allTests = [
        ("testParse", testParse),
    ]

    let service = SSDPService(host: "192.168.1.1", response: response)

    func testParse() {
        XCTAssertEqual("192.168.1.1", service.host)
        XCTAssertEqual("upnp:rootdevice", service.searchTarget!)
        XCTAssertEqual("uuid:111111111-2222-3333-4444-000000000000::upnp:rootdevice", service.uniqueServiceName!)
        XCTAssertEqual("system/system UPnP/1.1 MiniUPnPd/1.8", service.server!)
        XCTAssertEqual("http://192.168.1.1:10000/root.xml", service.location!)
    }
}
