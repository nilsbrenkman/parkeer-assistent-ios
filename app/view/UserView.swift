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

    @State private var refreshTask: Task<Void, Never>?

    var body: some View {
        Form {
            ParkingView()
            VisitorListView()
        }
        .listStyle(.insetGrouped)
        .padding(.top, Constants.padding.normal)
        .onAppear {
            if payment.isPaymentInProgress {
                let oldBalance = user.balance
                Task {
                    for i in 1..<11 {
                        try? await Task.sleep(nanoseconds: UInt64(i) * 1_000_000_000)
                        await user.getBalance()
                        if user.balance != oldBalance {
                            messages.addMessage(Lang.Payment.successMsg.localized(), type: .SUCCESS)
                            break
                        }
                    }
                    payment.isPaymentInProgress = false
                }
            }
            if !user.isLoaded {
                Task {
                    await visitors.getVisitors()
                    await user.getUser {
                        await parkings.getParking()
                    }
                    user.isLoaded = true
                    startRefreshTask()
                }
            } else {
                if Stats.user.requestReview() {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        Stats.user.requested = Date.now()
                        SKStoreReviewController.requestReview(in: windowScene)
                    }
                }
                startRefreshTask()
            }
        }
        .onDisappear {
            Log.info("Cancelling refresh task")
            refreshTask?.cancel()
            refreshTask = nil
        }
        .navigationBarHidden(true)

    }

    private func startRefreshTask() {
        guard refreshTask == nil else {
            return
        }
        refreshTask = Task {
            Log.info("Starting refresh task")

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
                    try? await Task.sleep(nanoseconds: UInt64(10 * 1000000000))
                    continue
                }

                for active in parking.active {
                    delay = min(delay, checkUpdate(active.endTime))
                }
                for scheduled in parking.scheduled {
                    delay = min(delay, checkUpdate(scheduled.startTime))
                }

                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1000000000))
                }
                await parkings.getParking()
            }
            Log.debug("Exiting refresh task")
        }
    }

}

#Preview {
    UserView()
        .setupPreview()
}
