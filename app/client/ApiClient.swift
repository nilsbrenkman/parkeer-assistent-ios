//
//  ApiClient.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 06/07/2021.
//

import Foundation
import SwiftUI

class ApiClient {

    static let client = ApiClient()

    static let COOKIE_KEY = "Cookies"

    public let baseUrl: String

    private let session: URLSession
    private let url: URL
    private var cookies: SessionCookies

    weak var errorHandler: ErrorHandler?

    private init() {
        baseUrl = Util.getSetting("ServerBaseURL")
        session = URLSession(configuration: .default)
        guard let url = URL(string: baseUrl) else {
            fatalError("ServerBaseURL is not a valid URL: \(baseUrl)")
        }
        self.url = url
        cookies = SessionCookies()

        if let json = UserDefaults.standard.string(forKey: ApiClient.COOKIE_KEY) {
            setCookies(json)
        }
    }

    func registerErrorHandler(_ errorHandler: ErrorHandler) {
        self.errorHandler = errorHandler
    }

    func throwError(_ error: ClientError) {
        errorHandler?.handleError(error)
    }

    func call<RESPONSE: Decodable>(_ result: RESPONSE.Type, path: String, method: Method)
        async throws -> RESPONSE
    {
        let body: Response? = nil
        return try await call(result, path: path, method: method, body: body)
    }

    func call<REQUEST: Encodable, RESPONSE: Decodable>(
        _ result: RESPONSE.Type,
        path: String,
        method: Method,
        body: REQUEST? = nil
    ) async throws -> RESPONSE {

        let httpTask = Task.detached(priority: .userInitiated) { [path, method, body] in

            guard let url = URL(string: self.baseUrl + path) else {
                throw ClientError.InvalidPath
            }
            Log.debug("Request: \(url) \(method.rawValue)")

            var headers = HTTPCookie.requestHeaderFields(with: self.getCookies())
            self.addAnalyticHeaders(&headers)

            var request = URLRequest(url: url)
            request.allHTTPHeaderFields = headers
            request.httpMethod = method.rawValue

            if body != nil {
                let json: Data
                do {
                    json = try JSONEncoder().encode(body)
                } catch {
                    Log.error("Request body encoding failed for \(url): \(error.localizedDescription)")
                    throw ClientError.RequestSerialization
                }
                Log.debug("Body: \(String(decoding: json, as: UTF8.self))")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = json
            }

            let (data, response) = try await self.session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClientError.NoHttpResponse
            }

            self.updateCookies(httpResponse)

            Log.debug("Status code: \(httpResponse.statusCode)")

            if httpResponse.statusCode / 100 != 2 {
                switch httpResponse.statusCode {
                case 401, 403:
                    throw ClientError.Unauthorized
                default:
                    let message = String(decoding: data, as: UTF8.self)
                    throw ClientError.ServerError(message)
                }
            }

            Log.debug("Response: \(String(decoding: data, as: UTF8.self))")

            do {
                return try JSONDecoder().decode(RESPONSE.self, from: data)
            } catch {
                Log.error("Response decoding failed for \(url): \(error.localizedDescription)")
                throw ClientError.ResponseSerialization
            }
        }

        do {
            return try await httpTask.value
        } catch {
            if let clientError = error as? ClientError {
                throwError(clientError)
            }
            throw error
        }

    }

    private func persistCookies() {
        var persistCookies: [PersistCookie] = []
        for cookie in getCookies() {
            persistCookies.append(
                PersistCookie(
                    name: cookie.name,
                    value: cookie.value,
                    domain: cookie.domain,
                    path: cookie.path
                )
            )
        }

        guard let data = try? JSONEncoder().encode(PersistCookies(cookies: persistCookies)),
            let json = String(data: data, encoding: .utf8)
        else {
            print("Unable to serialize cookies")
            return
        }
        UserDefaults.standard.set(json, forKey: ApiClient.COOKIE_KEY)
    }

    public func setCookies(_ cookies: String) {
        if let data = cookies.data(using: .utf8),
            let persistCookies = try? JSONDecoder().decode(PersistCookies.self, from: data)
        {

            for persistCookie in persistCookies.cookies {
                if let cookie = HTTPCookie(properties: [
                    HTTPCookiePropertyKey.name: persistCookie.name,
                    HTTPCookiePropertyKey.value: persistCookie.value,
                    HTTPCookiePropertyKey.domain: persistCookie.domain,
                    HTTPCookiePropertyKey.path: persistCookie.path,
                ]) {
                    _ = setCookie(cookie)
                }
            }
        }
    }

    private func setCookie(_ cookie: HTTPCookie) -> Bool {
        switch cookie.name {
        case "token":
            if cookies.token == nil || cookies.token!.value != cookie.value {
                cookies.token = cookie
                return true
            }
            return false
        case "product_id":
            if cookies.productId == nil || cookies.productId!.value != cookie.value {
                cookies.productId = cookie
                return true
            }
            return false
        default:
            print("Ignoring cookie \(cookie.name)")
        }
        return false
    }

    private func getCookies() -> [HTTPCookie] {
        var list: [HTTPCookie] = []
        if let token = cookies.token {
            list.append(token)
        }
        if let productId = cookies.productId {
            list.append(productId)
        }
        return list
    }

    private func updateCookies(_ httpResponse: HTTPURLResponse) {
        if httpResponse.statusCode >= 400 {
            UserDefaults.standard.removeObject(forKey: ApiClient.COOKIE_KEY)
            cookies = SessionCookies()
            return
        }
        var updated = false
        if let responseHeaderFields = httpResponse.allHeaderFields as? [String: String] {
            let responseCookies = HTTPCookie.cookies(
                withResponseHeaderFields: responseHeaderFields,
                for: url
            )

            for responseCookie in responseCookies {
                if setCookie(responseCookie) {
                    updated = true
                }
            }
        }
        if updated {
            persistCookies()
        }
    }

    private func addAnalyticHeaders(_ headers: inout [String: String]) {
        if let uuid = UIDevice.current.identifierForVendor?.uuidString,
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        {

            let os = ProcessInfo.processInfo.operatingSystemVersion

            headers["X-ParkeerAssistent-UserId"] = uuid
            headers["X-ParkeerAssistent-OS"] = "iOS"
            headers["X-ParkeerAssistent-SDK"] =
                String(os.majorVersion) + "." + String(os.minorVersion) + "."
                + String(os.patchVersion)
            headers["X-ParkeerAssistent-Version"] = version
            headers["X-ParkeerAssistent-Build"] = build
//            headers["X-ParkeerAssistent-Mock"] = "true"
        }
    }

}

enum Method: String {
    case GET
    case POST
    case DELETE
}

protocol ErrorHandler: AnyObject {
    func handleError(_ error: ClientError)
}

enum ClientError: Error {
    case InvalidPath
    case RequestSerialization
    case ResponseSerialization
    case NoHttpResponse
    case Unauthorized
    case ServerError(String)
    case EmptyResponse
}

struct SessionCookies {
    var token: HTTPCookie?
    var productId: HTTPCookie?
}

struct PersistCookies: Codable {
    var cookies: [PersistCookie] = []
}

struct PersistCookie: Codable {
    var name: String
    var value: String
    var domain: String
    var path: String
}
