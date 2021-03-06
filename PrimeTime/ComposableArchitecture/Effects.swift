import Combine

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
