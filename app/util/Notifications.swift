//
//  Notifications.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 12/07/2021.
//

import Foundation
import UserNotifications

class Notifications {

    static let store = Notifications()

    static let START_KEY = "notifyStart"
    static let STOP_KEY = "notifyStop"
    static let REMINDER_KEY = "notifyReminder"
    static let INTERVAL_KEY = "notifyInterval"

    static let INTERVAL_VALUES = [15, 30, 60, 2 * 60, 3 * 60, 4 * 60]
    static let INTERVAL_LABELS = ["15 m", "30 m", "1 h", "2 h", "3 h", "4 h"]

    var authorised = false
    var visitors: [Visitor]? = nil

    private init() {
        //
    }

    func parking(_ parking: ParkingResponse) {
        if Util.isUITest() {
            // prevent the notification permission alert from interrupting UI tests
            return
        }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for parking in parking.active {
            do { try scheduleReminders(parking) } catch { Log.error("scheduleReminders failed for parking \(parking.id): \(error.localizedDescription)") }
            do { try scheduleEnd(parking) } catch { Log.error("scheduleEnd failed for parking \(parking.id): \(error.localizedDescription)") }
        }
        for parking in parking.scheduled {
            do { try scheduleStart(parking) } catch { Log.error("scheduleStart failed for parking \(parking.id): \(error.localizedDescription)") }
            do { try scheduleEnd(parking) } catch { Log.error("scheduleEnd failed for parking \(parking.id): \(error.localizedDescription)") }
            do { try scheduleReminders(parking) } catch { Log.error("scheduleReminders failed for parking \(parking.id): \(error.localizedDescription)") }
        }
    }

    func scheduleStart(_ parking: Parking) throws {
        if !UserDefaults.standard.bool(forKey: Notifications.START_KEY) {
            return
        }
        let subtitle = try subtitle(parking)
        let date = try Util.parseDate(parking.startTime)
        schedule(String(format: "\(parking.id)_start"), title: "Parkeer sessie begint", subtitle: subtitle, date: date)
    }

    func scheduleEnd(_ parking: Parking) throws {
        if !UserDefaults.standard.bool(forKey: Notifications.STOP_KEY) {
            return
        }
        let subtitle = try subtitle(parking)
        let date = try Util.parseDate(parking.endTime)
        schedule(String(format: "\(parking.id)_end"), title: "Parkeer sessie loopt af", subtitle: subtitle, date: date)
    }

    func scheduleReminders(_ parking: Parking) throws {
        if !UserDefaults.standard.bool(forKey: Notifications.REMINDER_KEY) {
            return
        }
        let storedIndex = Int(UserDefaults.standard.double(forKey: Notifications.INTERVAL_KEY))
        let clampedIndex = max(0, min(storedIndex, Notifications.INTERVAL_VALUES.count - 1))
        let interval = Notifications.INTERVAL_VALUES[clampedIndex] * 60

        var reminder = try Util.parseDate(parking.startTime).addingTimeInterval(TimeInterval(interval))
        while reminder.timeIntervalSinceNow < 0 {
            reminder = reminder.addingTimeInterval(TimeInterval(interval))
        }
        let stop = try Util.parseDate(parking.endTime)
        let subtitle = try subtitle(parking)
        var counter = 0
        while reminder.timeIntervalSince(stop) < 0 {
            schedule(String(format: "\(parking.id)_reminder_\(counter)"), title: "Herinnering", subtitle: subtitle, date: reminder)
            reminder = reminder.addingTimeInterval(TimeInterval(interval))
            counter += 1
        }
    }

    func subtitle(_ parking: Parking) throws -> String {
        guard let visitor = Util.getVisitor(parking, visitors: visitors) else {
            Log.warning("Notifications.subtitle: visitor not found for parking \(parking.id) license '\(parking.license)'")
            throw GenericError.VisitorNotFound
        }
        let license = License.formatLicense(visitor.license)
        if let name = visitor.name {
            return "\(name) | [ \(license) ]"
        }
        return "[ \(license) ]"
    }

    func schedule(_ identifier: String, title: String, subtitle: String, date: Date) {
        if !authorised {
            requestAuthorization()
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.sound = UNNotificationSound(named: UNNotificationSoundName(Constants.sound.carHorn))
        content.interruptionLevel = .timeSensitive

        let timeInterval = Date.now().distance(to: date)
        if timeInterval < 10.0 {
            return
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                self.authorised = true
            } else if let error = error {
                Log.error("Notifications authorization failed: \(error.localizedDescription)")
            }
        }
    }

}
