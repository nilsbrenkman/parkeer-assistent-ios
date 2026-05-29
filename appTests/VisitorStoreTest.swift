//
//  VisitorStoreTest.swift
//  parkeerassistentTests
//

@testable import app
import Testing

@MainActor
struct VisitorStoreTest {

    private func makeVisitor(id: Int, license: String = "AB-001", name: String? = "Alice") -> Visitor {
        Visitor(id: id, license: license, formattedLicense: license, name: name)
    }

    @Test func getVisitorsSortsAndStores() async {
        let client = MockVisitorClient()
        client.getResult = .success(VisitorResponse(visitors: [
            makeVisitor(id: 1, name: "Bob"),
            makeVisitor(id: 2, name: "Alice")
        ]))
        let store = VisitorStore(visitorClient: client)

        await store.getVisitors()

        #expect(store.visitors?.count == 2)
        #expect(store.visitors?.first?.name == "Alice")
    }

    @Test func getVisitorsLeavesStateUnchangedOnError() async {
        let client = MockVisitorClient()
        client.getResult = .failure(ClientError.NoHttpResponse)
        let store = VisitorStore(visitorClient: client)

        await store.getVisitors()

        #expect(store.visitors == nil)
    }

    @Test func addVisitorInvokesClientAndRefreshes() async {
        let client = MockVisitorClient()
        client.getResult = .success(VisitorResponse(visitors: [makeVisitor(id: 1)]))
        let store = VisitorStore(visitorClient: client)

        var onSuccessCalled = false
        await store.addVisitor(license: "XY-99", name: "Eve") {
            onSuccessCalled = true
        }

        #expect(client.addCalls.count == 1)
        #expect(client.addCalls.first?.license == "XY-99")
        #expect(onSuccessCalled)
        #expect(store.visitors?.count == 1)
    }

    @Test func deleteVisitorInvokesClientAndRefreshes() async {
        let client = MockVisitorClient()
        client.getResult = .success(VisitorResponse(visitors: []))
        let store = VisitorStore(visitorClient: client)
        let visitor = makeVisitor(id: 5)

        await store.deleteVisitor(visitor)

        #expect(client.deleteCalls.count == 1)
        #expect(client.deleteCalls.first?.id == 5)
    }

    @Test func getNameReturnsMatchingVisitorName() async {
        let client = MockVisitorClient()
        client.getResult = .success(VisitorResponse(visitors: [
            makeVisitor(id: 1, license: "AB-001", name: "Alice")
        ]))
        let store = VisitorStore(visitorClient: client)
        await store.getVisitors()

        #expect(store.getName(from: "ab-001") == "Alice")
        #expect(store.getName(from: "missing") == "")
    }
}
