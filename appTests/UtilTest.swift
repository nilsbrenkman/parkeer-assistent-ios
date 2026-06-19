//
//  UtilTest.swift
//  parkeerassistentTests
//
//  Created by Nils Brenkman on 29/06/2021.
//

@testable import app
import Foundation
import Testing

struct UtilTest {

    /// Builds an ISO-8601 string that, when parsed by `Util.dateTimeFormatter`
    /// (which renders in the system's local zone), produces the given local
    /// wall-clock components. Keeps timezone-sensitive assertions stable
    /// across machines/CI.
    private func isoStringInLocalZone(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> String {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        let date = Calendar.current.date(from: comps)!
        return Util.dateTimeFormatter.string(from: date)
    }

    @Test func parseDateTimeReturnsDate() throws {
        let date = try Util.parseDate("2021-06-29T15:51:45+00:00")
        // 2021-06-29T15:51:45Z = 1624981905 since the epoch.
        #expect(date.timeIntervalSince1970 == 1624981905)
    }

    @Test func parseDateThrowsOnInvalidInput() {
        #expect(throws: GenericError.self) {
            try Util.parseDate("not a date")
        }
    }

    @Test func formatTimeReturnsHourMinute() {
        // `timeFormatter` renders in the test machine's local zone, so build
        // the input so the local rendering is fixed regardless of where the
        // suite runs.
        let input = isoStringInLocalZone(year: 2021, month: 6, day: 29, hour: 15, minute: 51)
        #expect(Util.formatTime(input) == "15:51")
    }

    @Test func formatTimeReturnsEmptyOnInvalidInput() {
        #expect(Util.formatTime("garbage") == "")
    }

    @Test func formatDateReturnsDayAndMonth() {
        // `dayMonthFormatter` uses "d MMM" (localized month), so just assert the
        // shape: starts with the day and is non-empty.
        let formatted = Util.formatDate("2021-06-29T15:51:45+00:00")
        #expect(formatted.hasPrefix("29 "))
        #expect(formatted.count > 3)
    }

    @Test func formatDateReturnsEmptyOnInvalidInput() {
        #expect(Util.formatDate("garbage") == "")
    }

    @Test func formatCostFormatsWithTwoDecimals() {
        #expect(Util.formatCost(0) == "0.00")
        #expect(Util.formatCost(1.5) == "1.50")
        #expect(Util.formatCost(2.345) == "2.35")
    }

    @Test func calculateCostScalesHourRateByMinutes() {
        #expect(Util.calculateCost(minutes: 60, hourRate: 1.20) == "1.20")
        #expect(Util.calculateCost(minutes: 30, hourRate: 2.40) == "1.20")
        #expect(Util.calculateCost(minutes: 0, hourRate: 5.00) == "0.00")
    }

    @Test func calculateCostReturnsZeroWhenHourRateMissing() {
        #expect(Util.calculateCost(minutes: 60, hourRate: nil) == "0.00")
    }

    @Test func calculformatDateTimeConvertsBalanceToMinutes() {
        #expect(Util.calculateTimeBalance(balance: "2.40", hourRate: 1.20) == 120)
        #expect(Util.calculateTimeBalance(balance: "0.60", hourRate: 1.20) == 30)
    }

    @Test func calcuformatDateTimeeReturnsZeroWhenInputsMissing() {
        #expect(Util.calculateTimeBalance(balance: nil, hourRate: 1.20) == 0)
        #expect(Util.calculateTimeBalance(balance: "1.00", hourRate: nil) == 0)
        #expect(Util.calculateTimeBalance(balance: "not a number", hourRate: 1.20) == 0)
    }

    @Test func formatDateTimeReformatsValidIsoString() {
        let input = isoStringInLocalZone(year: 2021, month: 6, day: 29, hour: 15, minute: 51)
        #expect(Util.formatDateTime(input) == "29/06 15:51")
    }

    @Test func formatDateTimeReturnsEmptyOnInvalidInput() {
        #expect(Util.formatDateTime("nope") == "")
    }

    @Test func convertDateAppliesProvidedFormatter() {
        let result = Util.convertDate("2021-06-29T15:51:45+00:00", formatter: Util.dateFormatter)
        #expect(result == "2021-06-29")
    }

    @Test func convertDateReturnsEmptyOnInvalidInput() {
        #expect(Util.convertDate("nope", formatter: Util.timeFormatter) == "")
    }

    @Test func getRegimeDayReturnsMatchingDay() throws {
        let regime = Regime(days: [
            RegimeDay(weekday: "MON", startTime: "09:00", endTime: "17:00"),
            RegimeDay(weekday: "TUE", startTime: "09:00", endTime: "21:00"),
        ])
        // 2021-06-29 is a Tuesday.
        let date = try Util.parseDate("2021-06-29T12:00:00+00:00")
        #expect(Util.getRegimeDay(regime: regime, date: date)?.weekday == "TUE")
    }

    @Test func getRegimeDayReturnsNilWhenNoMatch() throws {
        let regime = Regime(days: [
            RegimeDay(weekday: "MON", startTime: "09:00", endTime: "17:00"),
        ])
        // 2021-06-29 is a Tuesday — no match.
        let date = try Util.parseDate("2021-06-29T12:00:00+00:00")
        #expect(Util.getRegimeDay(regime: regime, date: date) == nil)
    }

    @Test func getVisitorMatchesFormattedLicense() {
        let visitor = Visitor(id: 1, license: "AB123C", formattedLicense: "AB-123-C", name: "Alice")
        let parking = Parking(id: 1, license: "AB-123-C", startTime: "", endTime: "", cost: 0)
        #expect(Util.getVisitor(parking, visitors: [visitor])?.id == 1)
    }

    @Test func getVisitorMatchesRawLicense() {
        let visitor = Visitor(id: 2, license: "AB123C", formattedLicense: "AB-123-C", name: "Bob")
        let parking = Parking(id: 1, license: "AB123C", startTime: "", endTime: "", cost: 0)
        #expect(Util.getVisitor(parking, visitors: [visitor])?.id == 2)
    }

    @Test func getVisitorReturnsNilWhenNoMatchOrListMissing() {
        let visitor = Visitor(id: 1, license: "AB123C", formattedLicense: "AB-123-C", name: "Alice")
        let parking = Parking(id: 1, license: "XX-999-Z", startTime: "", endTime: "", cost: 0)
        #expect(Util.getVisitor(parking, visitors: [visitor]) == nil)
        #expect(Util.getVisitor(parking, visitors: nil) == nil)
    }

}
