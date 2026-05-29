//
//  SessionStoreTest.swift
//  parkeerassistentTests
//

@testable import app
import Testing

@MainActor
struct SessionStoreTest {

    @Test func loggedInReflectsSuccessfulResponse() async {
        let client = MockLoginClient()
        client.loggedInResult = .success(Response(success: true))
        let store = SessionStore(loginClient: client)

        await store.loggedIn()

        #expect(store.isLoggedIn)
        #expect(store.isLoading == false)
    }

    @Test func loggedInFailsClosedOnError() async {
        let client = MockLoginClient()
        client.loggedInResult = .failure(ClientError.NoHttpResponse)
        let store = SessionStore(loginClient: client)

        await store.loggedIn()

        #expect(store.isLoggedIn == false)
        #expect(store.isLoading == false)
    }

    @Test func loginSucceedsAndSetsLoggedIn() async {
        let client = MockLoginClient()
        client.loginResult = .success(Response(success: true))
        let store = SessionStore(loginClient: client)

        await store.login(username: "user", password: "pw", storeCredentials: false)

        #expect(store.isLoggedIn)
        #expect(client.loginCalls.first?.username == "user")
    }

    @Test func loginDoesNotSetLoggedInOnUnauthorized() async {
        let client = MockLoginClient()
        client.loginResult = .failure(ClientError.Unauthorized)
        let store = SessionStore(loginClient: client)

        await store.login(username: "user", password: "wrong", storeCredentials: false)

        #expect(store.isLoggedIn == false)
    }

    @Test func logoutClearsSessionState() async {
        let client = MockLoginClient()
        let store = SessionStore(loginClient: client)
        store.isLoggedIn = true
        store.isLoading = true

        await store.logout()

        #expect(store.isLoggedIn == false)
        #expect(store.isLoading == false)
        #expect(client.logoutCallCount == 1)
    }
}
