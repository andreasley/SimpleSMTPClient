import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SimpleSMTPClientTests.allTests),
    ]
}
#endif
