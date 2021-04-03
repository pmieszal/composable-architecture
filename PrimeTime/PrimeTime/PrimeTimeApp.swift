import SwiftUI
import ComposableArchitecture
@testable import Counter

@main
struct PrimeTimeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(
                    initialValue: AppState(),
                    reducer: with(
                        appReducer,
                        compose(
                            logging, activityFeed
                        )
                    )
                )
            )
        }
    }
    
    init() {
        if ProcessInfo.processInfo.environment["UI_TESTS"] == "1" {
          Counter.Current.nthPrime = { _ in .sync { 3 } }
        }
    }
}
