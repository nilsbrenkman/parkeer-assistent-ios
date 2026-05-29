//
//  AddParkingView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 27/06/2021.
//

import SwiftUI

struct AddParkingView: View {
    
    @EnvironmentObject var user: UserStore
    @EnvironmentObject var parkings: ParkingStore
    @EnvironmentObject var router: Router
    
    let visitor: Visitor
    
    let config = Config(
        radius: 50,
        size: 12
    )
    
    let calendarDelegate = CalenderViewDelegate()
    
    @State private var minutes = 0
    @State private var startDate = Date.now()
    @State private var startTime = ""
    @State private var endTime = ""
    @State private var cost = "0.00"
    
    @State private var customStartDate = false
    @State private var modifyStartTime = false
    @State private var showDatePicker = false
    @State private var wait: Bool = false
    @State private var showMap: Bool = false
    
    var body: some View {
        Form {
            Section {
                
                VStack(alignment: .center, spacing: Constants.spacing.normal) {
                    
                    VisitorView(visitor: visitor)
                    
                    HStack(alignment: .center, spacing: Constants.spacing.normal) {
                        DataBox(title: Lang.Parking.date.localized(), content: "\(Util.dayMonthFormatter.string(from: startDate))")
                            .onTapGesture {
                                calendarDelegate.onSelectDate = { d in
                                    Log.info("Selected date: \(Util.dateFormatter.string(from: d))")
                                    startDate = d
                                    updateRegime()
                                    showDatePicker = false
                                }
                                calendarDelegate.regime = user.regime
                                showDatePicker.toggle()
                            }
                            .opacity(opacity(enabled: showDatePicker))
                            .accessibility(identifier: "start-date")
                        DataBox(title: Lang.Parking.startTime.localized(), content: "\(startTime)")
                            .onTapGesture {
                                self.modifyStartTime = true
                            }
                            .opacity(opacity(enabled: modifyStartTime))
                            .accessibility(identifier: "start-time")
                        VStack(alignment: .leading, spacing: Constants.spacing.xSmall) {
                            Text("\(Lang.Parking.sign.localized()):")
                                .font(Font.ui.dataBoxTitle)
                            ZStack {
                                RoundedRectangle(cornerRadius: Constants.radius.small, style: .continuous)
                                    .fill(Color.ui.header)
                                    .frame(height: 48)
                                if let id = user.parkingMeterId {
                                    Text("\(String(id))")
                                        .font(Font.ui.dataBoxContent)
                                        .bold()
                                        .foregroundColor(.white)
                                } else {
                                    Text("...")
                                        .font(Font.ui.dataBoxContent)
                                        .bold()
                                        .foregroundColor(Color.ui.danger)
                                }
                            }
                        }
                        .onTapGesture {
                            showMap = true
                        }
                    }
                    
                    HStack(alignment: .center, spacing: Constants.spacing.normal) {
                        DataBox(title: Lang.Parking.minutes.localized(), content: "\(minutes)")
                        DataBox(title: Lang.Parking.endTime.localized(), content: "\(endTime)")
                        DataBox(title: Lang.Parking.cost.localized(), content: "€ \(cost)")
                    }
                    .onTapGesture(perform: {
                        self.modifyStartTime = false
                    })
                    .opacity(opacity(enabled: !showDatePicker && !modifyStartTime))
                    
                    WheelSelector(config: Config(
                        radius: 75,
                        size: 16
                    ), onChange: onChange)
                }
                .padding(.vertical, Constants.padding.normal)
            }
            
            Section {
                Button(action: {
                    if !wait && minutes > 0 {
                        Task {
                            wait = true
                            await parkings.startParking(visitor, timeMinutes: minutes, start: startDate, user: user) {
                                router.popScreen()
                            }
                            wait = false
                        }
                    }
                }) {
                    Text(Lang.Common.add.localized())
                        .font(.title3)
                        .bold()
                        .wait($wait)
                }
                .style(.success, disabled: minutes <= 0 || user.parkingMeterId == nil)
            }
        }
        .modal(visible: $showDatePicker, onClose: updateRegime) {
            DatePickerModal(date: $startDate, delegate: calendarDelegate)
        }
        .onAppear(perform: {
            update()
        })
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                if Task.isCancelled { return }
                if !showDatePicker {
                    update()
                }
            }
        }
        .pageTitle(Lang.Parking.start.localized(), dismiss: router.popScreen)
        .fullScreenCover(isPresented: $showMap) {
            ParkingMeterView { meter in
                user.setParkingMeter(meter.id)
                showMap = false
            }
        }
    }
    
    private func onChange(diff: Int) {
        if modifyStartTime {
            customStartDate = true
            startDate.addTimeInterval(Double(diff * 60))
            update()
            return
        }
        let minutesVal = minutes + diff
        if minutesVal < 0 {
            minutes = 0
        } else if minutesVal > user.timeBalance {
            minutes = user.timeBalance
        } else {
            updateMinutes(minutesVal)
        }
        update()
    }
    
    private func update() {
        updateStartDate(customStartDate ? startDate : minimumStartTime())
        startTime = Util.timeFormatter.string(from: startDate)
        updateMinutes(minutes)
        let endDate = Date(timeInterval: TimeInterval(minutes * 60), since: startDate)
        endTime = Util.timeFormatter.string(from: endDate)
    }
    
    private func updateMinutes(_ minutes: Int) {
        let endTime = Date(timeInterval: TimeInterval(minutes * 60), since: startDate)
        if endTime > regimeEndTime() {
            let minutesToEnd = Int((regimeEndTime().timeIntervalSince(startDate) / 60).rounded(.up))
            self.minutes = minutesToEnd
        } else {
            self.minutes = minutes
        }
        cost = Util.calculateCost(minutes: self.minutes, hourRate: user.hourRate)
    }
    
    private func updateStartDate(_ start: Date) {
        if start > regimeEndTime() {
            startDate = regimeEndTime()
            return
        }
        if start > minimumStartTime() {
            startDate = start
            customStartDate = true
        } else {
            startDate = minimumStartTime()
            customStartDate = false
        }
    }
    
    private func updateRegime() {
        Task {
            await user.getRegime(startDate)
            update()
        }
    }
    
    private func minimumStartTime() -> Date {
        if !today() {
            return regimeStartTime()
        }
        if regimeStartTime() > Date.now() {
            return regimeStartTime()
        }
        if regimeEndTime() < Date.now() {
            return regimeEndTime()
        }
        return Date.now()
    }
    
    private func today() -> Bool {
        Calendar.current.isDate(startDate, inSameDayAs: Date.now())
    }
    
    private func regimeStartTime() -> Date {
        user.regimeTimeStart ?? Date.now()
    }
    
    private func regimeEndTime() -> Date {
        user.regimeTimeEnd ?? Date.now()
    }
    
    private func opacity(enabled: Bool) -> Double {
        if enabled {
            return 1.0
        }
        return 0.5
    }
    
}

#if DEBUG
#Preview {
    AddParkingView(visitor: Visitor(id: 1, license: "123ABC", formattedLicense: "123-A-BC", name: "John Doe"))
        .setupPreview()
}
#endif
