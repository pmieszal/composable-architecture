import XCTest
@testable import Counter

class CounterTests: XCTestCase {
    func testIncrTapped() throws {
        var state = CounterViewState(
            alertNthPrime: nil,
            count: 2,
            favoritePrimes: [3, 5],
            isNthPrimeButtonDisabled: false)
        
        let effects = counterViewReducer(&state, .counter(.incrTapped))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 3,
                favoritePrimes: [3, 5],
                isNthPrimeButtonDisabled: false))
        XCTAssert(effects.isEmpty)
    }
    
    func testDecrTapped() throws {
        var state = CounterViewState(
            alertNthPrime: nil,
            count: 2,
            favoritePrimes: [3, 5],
            isNthPrimeButtonDisabled: false)
        
        let effects = counterViewReducer(&state, .counter(.decrTapped))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 1,
                favoritePrimes: [3, 5],
                isNthPrimeButtonDisabled: false))
        XCTAssert(effects.isEmpty)
    }
    
    func testNthPrimeButtonHappyFlow() throws {
        var state = CounterViewState(
            alertNthPrime: nil,
            count: 2,
            favoritePrimes: [3, 5],
            isNthPrimeButtonDisabled: false)
        
        var effects = counterViewReducer(&state, .counter(.nthPrimeButtonTapped))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 2,
                favoritePrimes: [3, 5],
                isNthPrimeButtonDisabled: true))
        XCTAssertEqual(effects.count, 1)
        
        effects = counterViewReducer(&state, .counter(.nthPrimeResponse(3)))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: PrimeAlert(prime: 3),
                count: 2,
                favoritePrimes: [3, 5],
                isNthPrimeButtonDisabled: false))
        XCTAssert(effects.isEmpty)
        
        
        effects = counterViewReducer(&state, .counter(.alertDismissTapped))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 2,
                favoritePrimes: [3, 5],
                isNthPrimeButtonDisabled: false))
        XCTAssert(effects.isEmpty)
    }
    
    func testNthPrimeButtonUnappyFlow() throws {
        var state = CounterViewState(
            alertNthPrime: nil,
            count: 2,
            favoritePrimes: [3, 5],
            isNthPrimeButtonDisabled: false)
        
        var effects = counterViewReducer(&state, .counter(.nthPrimeButtonTapped))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 2,
                favoritePrimes: [3, 5],
                isNthPrimeButtonDisabled: true))
        XCTAssertEqual(effects.count, 1)
        
        effects = counterViewReducer(&state, .counter(.nthPrimeResponse(nil)))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 2,
                favoritePrimes: [3, 5],
                isNthPrimeButtonDisabled: false))
        XCTAssert(effects.isEmpty)
    }
    
    func testPrimeModal() throws {
        var state = CounterViewState(
            alertNthPrime: nil,
            count: 2,
            favoritePrimes: [3, 5],
            isNthPrimeButtonDisabled: false)
        
        var effects = counterViewReducer(&state, .primeModal(.saveFavoritePrimeTapped))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 2,
                favoritePrimes: [3, 5, 2],
                isNthPrimeButtonDisabled: false))
        XCTAssert(effects.isEmpty)
        
        effects = counterViewReducer(&state, .primeModal(.removeFavoritePrimeTapped))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 2,
                favoritePrimes: [3, 5],
                isNthPrimeButtonDisabled: false))
        XCTAssert(effects.isEmpty)
    }
}
