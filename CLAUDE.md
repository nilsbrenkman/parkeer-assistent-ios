# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The **iOS client** for ParkeerAssistent (Amsterdam visitor parking permits) — a SwiftUI app and the
**reference implementation** the Android (`../android/`) and web (`../web/`) ports mirror. Changes to
screen behavior here ripple into those ports, so keep behavior changes deliberate.

The app talks **only to the sibling Ktor `../server/`** backend (never to Egis directly) — see
`../server/CLAUDE.md` for the API contract, cookie session (`token` + `product_id`; call `/user`
after login before parking/balance calls), and mock mode (`X-ParkeerAssistent-Mock: true` header,
login `test` / `1234`). Note the server's `model/` is **more current** than `app/util/Model.swift`.

This directory is its own git repo (`nilsbrenkman/parkeer-assistent-ios`); the parent directory is
an untracked workspace, not a monorepo root.

## Building & testing

- `parkeerassistent.xcodeproj`, scheme `app`, deployment target iOS 17, bundle id
  `nl.parkeer-assistent.amsterdam`. No external package manager setup.
- Server base URL comes from the `ServerBaseURL` setting (read via `Util.getSetting`).
- Tests: `appTests` (unit) + `appUITests` (UI), bundled in `app.xctestplan`:
  `xcodebuild test -project parkeerassistent.xcodeproj -scheme app -destination 'platform=iOS Simulator,name=iPhone 16'`
- CI: `.github/workflows/ios.yml` builds + tests the default scheme on `main` pushes/PRs.

## Architecture

Flow: **View → Store (`ObservableObject`) → Client → server**, all under `app/`:

- `client/` — `ApiClient.swift` (URLSession wrapper: cookies, analytics headers, commented-out mock
  header) + one thin `*Client.swift` per domain (Login, User, Visitor, Parking, Payment, Geo).
- `state/` — `ObservableObject` stores per domain (`SessionStore`, `UserStore`, `VisitorStore`,
  `ParkingStore`, `PaymentStore`, `AccountStore`, `ParkingMeterStore`, `MessageStore`) + `Router`.
  `SessionStore` owns login state; errors surface via `MessageStore`.
- `view/` — feature screens; `ContentView.swift` is the session-state-driven root.
- `components/` — reusable views (`DataBox`, `Property`, `Modal`, `WheelSelector`, `CalendarView`, …).
- `ui/` — design tokens (`Color`, `Font`, `Constants`), `Lang.swift` (i18n), `Preview.swift`
  (previews are **debug-only**).
- `util/` — `Model.swift` (API shapes), `Keychain.swift` (saved credentials + biometrics),
  `Notifications.swift` (local notifications at parking end), `License.swift`, `Stats.swift`.
- i18n: `en.lproj` (default) + `nl.lproj`.

Native features the ports approximate rather than copy: biometric saved login, exact-time local
notifications, the map-based parking-meter picker (`ParkingMeterView`), StoreKit review prompts,
and the rotary `WheelSelector` duration picker.
