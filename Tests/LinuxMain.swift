@testable import SSDPDiscoveryTests
@testable import SSDPServiceTests
import XCTest

XCTMain([
    testCase(SSDPDiscoveryTests.allTests),
    testCase(SSDPServiceTests.allTests),
])
