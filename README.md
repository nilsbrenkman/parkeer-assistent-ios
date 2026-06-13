# ParkeerAssistent — iOS

The iOS client for **ParkeerAssistent**, an app for Amsterdam visitor parking permits. Users
register their visitors and start/stop parking sessions without dealing with the city's upstream
portal.

This is a SwiftUI app and the **reference implementation** of the product: the Android
([parkeer-assistent-android](https://github.com/nilsbrenkman/parkeer-assistent-android)) and web
clients are ported from it and mirror its screens and behavior.

## How it fits in

The app never talks to the upstream Egis Parking Services API directly. It talks to the
[Kotlin/Ktor backend-for-frontend](https://github.com/nilsbrenkman/parkeer-assistent-server)
(live at [parkeerassistent.nl](https://parkeerassistent.nl)), which defines the API contract.
The server's `model/` package is the source of truth for request/response shapes; `app/util/Model.swift`
holds the client-side copies.

Two things every client must honor:

- **Session is two httpOnly cookies** set by the server: `token` (Egis bearer, from login) and
  `product_id` (active permit, set by `GET /user`). The app must call `/user` after login before
  parking/balance calls work; an upstream 401/redirect clears the session.
- **Mock mode**: sending the `X-ParkeerAssistent-Mock: true` header makes the server serve
  deterministic in-memory fixtures (login `test` / `1234`). Used for App Store review and testing —
  see the commented-out header in `app/client/ApiClient.swift`.

## Requirements & build

- Xcode with an iOS 17+ SDK (deployment target: iOS 17).
- Open `parkeerassistent.xcodeproj` and run the `app` scheme. No external package setup is needed.
- The server base URL comes from the `ServerBaseURL` setting (resolved via `Util.getSetting`).

Tests live in `appTests` (unit) and `appUITests` (UI), bundled by `app.xctestplan`:

```sh
xcodebuild test -project parkeerassistent.xcodeproj -scheme app \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

CI (`.github/workflows/ios.yml`) builds and tests the default scheme on any available iPhone
simulator for pushes and PRs on `main`.

## Project structure

```
app/
├── client/      One *Client.swift per API domain (Login, User, Visitor, Parking, Payment, Geo)
│                on top of ApiClient.swift (URLSession, cookies, analytics headers)
├── state/       ObservableObject stores (Session, User, Visitor, Parking, Payment, Account,
│                ParkingMeter, Message) + Router
├── view/        Feature screens (Login, User, Parking, Visitor, History, Payment, Settings, …);
│                ContentView.swift is the session-state-driven root
├── components/  Reusable views (DataBox, Property, Modal, WheelSelector, CalendarView, …)
├── ui/          Design tokens: Color, Font, Constants, Lang (i18n), Preview helpers
├── util/        Model.swift (API shapes), Keychain, Notifications, License, Stats, Util
├── en.lproj / nl.lproj   Localizations (English + Dutch)
└── resources/   Assets and other bundled resources
```

The flow is **View → Store (`ObservableObject`) → Client → server**. Notable native features:
saved credentials with biometrics (`util/Keychain.swift`), local notifications at parking end
times (`util/Notifications.swift`), a map-based parking-meter picker (`view/ParkingMeterView.swift`),
and StoreKit review prompts.
