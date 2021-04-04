import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest
@testable import Counter

extension Snapshotting where Value: UIViewController, Format == UIImage {
    static var windowedImage: Snapshotting {
        return Snapshotting<UIImage, UIImage>.image.asyncPullback { vc in
            Async<UIImage> { callback in
                UIView.setAnimationsEnabled(false)
                let window = UIApplication.shared.windows.first!
                window.rootViewController = vc
                DispatchQueue.main.async {
                    let image = UIGraphicsImageRenderer(bounds: window.bounds).image { ctx in
                        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                    }
                    
                    callback(image)
                    UIView.setAnimationsEnabled(true)
                }
            }
        }
    }
}

class CounterTests: XCTestCase {
    var environment: CounterEnvironment!
    
    override func setUp() {
        super.setUp()
        
        environment = { _ in .sync { 17 }}
    }
    
    func testSnapshots() {
        let store = Store(
            initialValue: CounterViewState(),
            reducer: counterViewReducer,
            environment: environment)
        let view = CounterView(store: store)
        let vc = UIHostingController(rootView: view)
        vc.view.frame = UIScreen.main.bounds
        
        // isRecording = true
        assertSnapshot(matching: vc, as: .windowedImage)
        
        /**
          sometimes we need to wait for a while to let simulator run UIHostingController,
          otherwise the first action falls out of the flow
         */
        
        let expectation = self.expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)

        store.send(.counter(.incrTapped))
        assertSnapshot(matching: vc, as: .windowedImage)

        store.send(.counter(.incrTapped))
        assertSnapshot(matching: vc, as: .windowedImage)

        /**
          ## probably iOS bug
          commenting out nthPrimeButton* actions, since it look like there is a bug in iOS 14.2
          and the effect is that when you assign nil to alertNthPrime,
          iOS is not hiding already displayed alert :(
         
         store.send(.counter(.nthPrimeButtonTapped))
         assertSnapshot(matching: vc, as: .windowedImage)

         var expectation = self.expectation(description: "wait")
         DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
             expectation.fulfill()
         }
         wait(for: [expectation], timeout: 1)
         assertSnapshot(matching: vc, as: .windowedImage)

         store.send(.counter(.alertDismissButtonTapped))
        
         expectation = self.expectation(description: "wait")
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
             expectation.fulfill()
         }
         wait(for: [expectation], timeout: 0.5)
         assertSnapshot(matching: vc, as: .windowedImage)
         */

        store.send(.counter(.isPrimeButtonTapped))
        assertSnapshot(matching: vc, as: .windowedImage)

        store.send(.primeModal(.saveFavoritePrimeTapped))
        assertSnapshot(matching: vc, as: .windowedImage)

        store.send(.counter(.primeModalDismissed))
        assertSnapshot(matching: vc, as: .windowedImage)
    }
    
    func testIncrDecrButtonTapped() throws {
        assert(
            initialValue: CounterViewState(count: 2),
            reducer: counterViewReducer,
            environment: environment,
            steps:
            Step(.send, .counter(.incrTapped)) { $0.count = 3 },
            Step(.send, .counter(.incrTapped)) { $0.count = 4 },
            Step(.send, .counter(.decrTapped)) { $0.count = 3 })
    }
    
    func testNthPrimeButtonHappyFlow() throws {
        environment = { _ in .sync { 17 } }
        
        assert(
            initialValue: CounterViewState(
                alertNthPrime: nil,
                isNthPrimeButtonDisabled: false),
            reducer: counterViewReducer,
            environment: environment,
            steps:
            Step(.send, .counter(.nthPrimeButtonTapped)) {
                $0.isNthPrimeButtonDisabled = true
            },
            Step(.receive, .counter(.nthPrimeResponse(17))) {
                $0.isNthPrimeButtonDisabled = false
                $0.alertNthPrime = PrimeAlert(prime: 17)
            },
            Step(.send, .counter(.alertDismissButtonTapped)) {
                $0.alertNthPrime = nil
            })
    }
    
    func testNthPrimeButtonUnappyFlow() throws {
        environment = { _ in .sync { nil } }
        
        assert(
            initialValue: CounterViewState(
                alertNthPrime: nil,
                isNthPrimeButtonDisabled: false),
            reducer: counterViewReducer,
            environment: environment,
            steps:
            Step(.send, .counter(.nthPrimeButtonTapped)) {
                $0.isNthPrimeButtonDisabled = true
            },
            Step(.receive, .counter(.nthPrimeResponse(nil))) {
                $0.isNthPrimeButtonDisabled = false
            })
    }
    
    func testPrimeModal() throws {
        assert(
            initialValue: CounterViewState(
                count: 1,
                favoritePrimes: [3, 5]),
            reducer: counterViewReducer,
            environment: environment,
            steps:
            Step(.send, .counter(.incrTapped)) {
                $0.count = 2
            },
            Step(.send, .primeModal(.saveFavoritePrimeTapped)) {
                $0.favoritePrimes = [3, 5, 2]
            },
            Step(.send, .primeModal(.removeFavoritePrimeTapped)) {
                $0.favoritePrimes = [3, 5]
            })
    }
}
