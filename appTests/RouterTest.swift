//
//  RouterTest.swift
//  parkeerassistentTests
//

@testable import app
import Testing

@MainActor
struct RouterTest {

    @Test func syncRootWhileLoadingClearsPath() {
        let router = Router()
        router.path = [.user, .info]

        router.syncRoot(isLoggedIn: true, isLoading: true, isBackground: false)

        #expect(router.path == [.user])
    }

    @Test func syncRootWhileBackgroundedClearsPath() {
        let router = Router()
        router.path = [.user]

        router.syncRoot(isLoggedIn: true, isLoading: false, isBackground: true)

        #expect(router.path == [.user])
    }

    @Test func syncRootRoutesToUserWhenLoggedIn() {
        let router = Router()

        router.syncRoot(isLoggedIn: true, isLoading: false, isBackground: false)

        #expect(router.path == [.user])
    }

    @Test func syncRootRoutesToLoginWhenLoggedOut() {
        let router = Router()
        router.path = [.user, .history]

        router.syncRoot(isLoggedIn: false, isLoading: false, isBackground: false)

        #expect(router.path == [.login])
    }
}
