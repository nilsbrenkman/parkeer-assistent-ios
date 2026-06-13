//
//  UserView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 13/06/2021.
//

import StoreKit
import SwiftUI

@MainActor
struct UserView: View {

    @EnvironmentObject var user: UserStore
    @EnvironmentObject var visitors: VisitorStore
    @EnvironmentObject var parkings: ParkingStore
    @EnvironmentObject var messages: MessageStore
    @EnvironmentObject var payment: PaymentStore

    var body: some View {
        Form {
            ParkingView()
            VisitorListView()
        }
        .listStyle(.insetGrouped)
        .task {
            if !user.isLoaded {
                await visitors.getVisitors()
                await user.getUser {
                    await parkings.getParking()
                }
                user.isLoaded = true
            } else if !Util.isUITest() && Stats.user.requestReview() {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    Stats.user.requested = Date.now()
                    SKStoreReviewController.requestReview(in: windowScene)
                }
            }
            await runRefreshLoop()
        }
        .task(id: payment.isPaymentInProgress) {
            guard payment.isPaymentInProgress else { return }
            let oldBalance = user.balance
            for i in 1..<11 {
                try? await Task.sleep(nanoseconds: UInt64(i) * 1_000_000_000)
                if Task.isCancelled { return }
                await user.getBalance()
                if user.balance != oldBalance {
                    messages.addMessage(Lang.Payment.successMsg.localized(), type: .SUCCESS)
                    break
                }
            }
            payment.isPaymentInProgress = false
        }
        .navigationBarHidden(true)

    }

    private func runRefreshLoop() async {
        Log.info("Starting refresh task")
        defer { Log.info("Exiting refresh task") }

        let checkUpdate: (String) -> Double = { time in
            if let date = try? Util.parseDate(time) {
                if date < Date.now() {
                    return 0
                }
                let interval = Date.now().distance(to: date)
                Log.debug("Interval until \(time, privacy: .public) is \(interval, privacy: .public)")
                return interval
            }
            Log.warning("Error parsing time \(time, privacy: .public)")
            return 60
        }

        while !Task.isCancelled {
            var delay = 60.0

            Log.debug("Running refresh task")

            guard let parking = parkings.parking else {
                Log.warning("No parking data, wait 10 seconds")
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                continue
            }

            for active in parking.active {
                delay = min(delay, checkUpdate(active.endTime))
            }
            for scheduled in parking.scheduled {
                delay = min(delay, checkUpdate(scheduled.startTime))
            }

            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            if Task.isCancelled { return }
            await parkings.getParking()
        }
    }

}

#if DEBUG
#Preview {
    UserView()
        .setupPreview()
}
#endif
