import Combine

public struct Effect<Output>: Publisher {
    public typealias Failure = Never
    
    let publisher: AnyPublisher<Output, Failure>
    
    public func receive<S>(
        subscriber: S
    ) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        publisher.receive(subscriber: subscriber)
    }
}

public extension Publisher where Failure == Never {
    func eraseToEffect() -> Effect<Output> {
        return Effect(publisher: eraseToAnyPublisher())
    }
}

public extension Effect {
    static func fireAndForget(work: @escaping () -> Void) -> Effect {
        Deferred { () -> Empty<Output, Never> in
            work()
            return Empty(completeImmediately: true)
        }
        .eraseToEffect()
    }
}

public extension Effect {
    static func sync(work: @escaping () -> Output) -> Effect {
        return Deferred {
            Just(work())
        }
        .eraseToEffect()
    }
}

/// (Never) -> A
func absurd<A>(_ never: Never) -> A {}

public extension Publisher where Output == Never, Failure == Never {
    func fireAndForget<A>() -> Effect<A> {
        map(absurd).eraseToEffect()
    }
}
