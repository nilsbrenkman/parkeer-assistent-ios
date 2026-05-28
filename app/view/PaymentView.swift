//
//  PaymentView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 20/08/2021.
//

import SwiftUI

@MainActor
struct PaymentView: View {

    @EnvironmentObject var app: AppModel
    @EnvironmentObject var user: UserModel

    @Environment(\.openURL) private var openURL

    enum PaymentMethod: String, CaseIterable, Identifiable {
        case ideal = "IDEAL"
        case creditCard = "CARDS"
        var id: String { rawValue }

        var label: String {
            switch self {
            case .ideal: return "iDeal | Wero"
            case .creditCard: return "Credit Card"
            }
        }

        var icon: String {
            switch self {
            case .ideal: return "Wero"
            case .creditCard: return "CreditCard"
            }
        }
    }

    private let amounts: [Int] = [250, 500, 1000, 1500, 2000, 3000, 4000, 5000, 10000]

    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    @State private var selectedAmount: Int = 0
    @State private var selectedMethod: String = ""
    @State private var wait: Bool = false

    var body: some View {
        Form {
            Section(header: SectionHeader(Lang.Payment.amount.localized())) {
                LazyVGrid(columns: columns, spacing: Constants.spacing.small) {
                    ForEach(amounts, id: \.self) { amount in
                        Button(action: {
                            selectedAmount = amount
                        }) {
                            Text("€ \(Util.formatCost(Double(amount) / 100))")
                                .font(.title3)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Constants.padding.normal)
                                .background(
                                    RoundedRectangle(cornerRadius: Constants.radius.normal, style: .continuous)
                                        .fill(
                                            selectedAmount == amount ? Color.ui.header : Color.ui.bw70
                                        )
                                )
                                .foregroundColor(selectedAmount == amount ? Color.ui.enabled : .primary)
                        }
                        .buttonStyle(.plain)
                        .accessibility(identifier: "amount-\(amount)")
                    }
                }
                .padding(.vertical, Constants.padding.small)
            }

            Section(header: SectionHeader(Lang.Payment.bank.localized())) {
                VStack(spacing: Constants.spacing.small) {
                    ForEach(PaymentMethod.allCases) { method in
                        Button(action: {
                            selectedMethod = method.rawValue
                        }) {
                            HStack(spacing: Constants.spacing.normal) {
                                Image(method.icon)
                                    .font(.title2)
                                    .frame(width: 100)
                                Spacer()
                                Text(method.label)
                                    .font(.title3)
                                    .bold()
                                Spacer()
                            }
                            .padding(.horizontal, Constants.padding.normal)
                            .padding(.vertical, Constants.padding.normal)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: Constants.radius.normal, style: .continuous)
                                    .fill(
                                        selectedMethod == method.rawValue ? Color.ui.header : Color.ui.bw70
                                    )
                            )
                            .foregroundColor(
                                selectedMethod == method.rawValue ? Color.ui.enabled : .primary
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibility(identifier: "method-\(method.rawValue)")
                    }
                }
                .padding(.vertical, Constants.padding.small)
            }

            Section {
                Button(action: {
                    Task {
                        wait = true
                        await user.payment(amount: selectedAmount, brand: selectedMethod) { url in
                            if let url = URL(string: url) {
                                openURL(url)
                            }
                        }
                        wait = false
                    }
                }) {
                    Text(Lang.Payment.start.localized())
                        .font(.title3)
                        .bold()
                        .wait($wait)
                }
                .style(.success, disabled: selectedAmount==0 || selectedMethod.isEmpty)
                .accessibility(identifier: "start-payment")
            }
        }
        .listStyle(.insetGrouped)
        .pageTitle(Lang.Payment.amount.localized(), dismiss: app.popScreen)
    }

}

#Preview {
    PaymentView()
        .setupPreview()
}
