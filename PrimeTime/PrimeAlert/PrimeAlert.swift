import Foundation

public struct PrimeAlert: Equatable, Identifiable {
    public let n: Int
    public let prime: Int
    public var id: Int { prime }
    
    public var title: String {
        return "The \(ordinal(n)) prime is \(prime)"
    }

    public init(n: Int, prime: Int) {
        self.n = n
        self.prime = prime
    }
}

public func ordinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(for: n) ?? ""
}
