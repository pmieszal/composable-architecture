import ComposableArchitecture
import XCTest
@testable import Counter

class CounterTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Current = .mock
    }
    
    func testIncrDecrButtonTapped() throws {
        assert(
            initialValue: CounterViewState(count: 2),
            reducer: counterViewReducer,
            steps:
            Step(.send, .counter(.incrTapped)) { $0.count = 3 },
            Step(.send, .counter(.incrTapped)) { $0.count = 4 },
            Step(.send, .counter(.decrTapped)) { $0.count = 3 })
    }
    
    func testNthPrimeButtonHappyFlow() throws {
        Current.nthPrime = { _ in .sync { 17 } }
        
        assert(
            initialValue: CounterViewState(
                alertNthPrime: nil,
                isNthPrimeButtonDisabled: false),
            reducer: counterViewReducer,
            steps:
            Step(.send, .counter(.nthPrimeButtonTapped)) {
                $0.isNthPrimeButtonDisabled = true
            },
            Step(.receive, .counter(.nthPrimeResponse(17))) {
                $0.isNthPrimeButtonDisabled = false
                $0.alertNthPrime = PrimeAlert(prime: 17)
            },
            Step(.send, .counter(.alertDismissTapped)) {
                $0.alertNthPrime = nil
            })
    }
    
    func testNthPrimeButtonUnappyFlow() throws {
        Current.nthPrime = { _ in .sync { nil } }
        
        assert(
            initialValue: CounterViewState(
                alertNthPrime: nil,
                isNthPrimeButtonDisabled: false),
            reducer: counterViewReducer,
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
                count: 2,
                favoritePrimes: [3, 5]),
            reducer: counterViewReducer,
            steps:
            Step(.send, .primeModal(.saveFavoritePrimeTapped)) {
                $0.favoritePrimes = [3, 5, 2]
            },
            Step(.send, .primeModal(.removeFavoritePrimeTapped)) {
                $0.favoritePrimes = [3, 5]
            })
    }
}
