//
//  VisitorStore.swift
//  parkeerassistent
//

import Foundation

@MainActor
class VisitorStore: ObservableObject {

    @Published var visitors: [Visitor]?

    private let visitorClient: VisitorClient

    init() {
        do {
            visitorClient = try ClientManager.instance.get(VisitorClient.self)
        } catch {
            fatalError("Failed to initialize VisitorStore: \(error)")
        }
    }

    func getVisitors() async {
        let response: VisitorResponse
        do {
            response = try await visitorClient.get()
        } catch {
            Log.error("getVisitors failed: \(error.localizedDescription)")
            return
        }

        let sorted = response.visitors.sorted()
        if sorted == visitors {
            return
        }
        visitors = sorted
        Notifications.store.visitors = sorted
    }

    func addVisitor(license: String, name: String, onSuccess: (() -> Void)? = nil) async {
        let response: Response
        do {
            response = try await visitorClient.add(license: license, name: name)
        } catch {
            Log.error("addVisitor failed: \(error.localizedDescription)")
            return
        }

        if response.success {
            onSuccess?()
            Stats.user.visitorCount += 1
            visitors = nil
            await getVisitors()
        } else {
            MessageStore.shared.addMessage(response.message, type: Type.ERROR)
        }
    }

    func deleteVisitor(_ visitor: Visitor) async {
        let response: Response
        do {
            response = try await visitorClient.delete(visitor)
        } catch {
            Log.error("deleteVisitor failed: \(error.localizedDescription)")
            return
        }

        if !response.success {
            MessageStore.shared.addMessage(response.message, type: Type.ERROR)
        }
        await getVisitors()
    }

    func getName(from licence: String) -> String {
        if let visitorList = visitors {
            for visitor in visitorList {
                if visitor.license.lowercased() == licence.lowercased() {
                    return visitor.name ?? ""
                }
            }
        }
        return ""
    }

}
