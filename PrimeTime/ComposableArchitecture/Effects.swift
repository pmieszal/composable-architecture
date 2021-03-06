import Foundation

public extension Effect where A == (Data?, URLResponse?, Error?) {
    func decode<M: Decodable>(as type: M.Type) -> Effect<M?> {
        map { data, response, error in
            data.flatMap { try? JSONDecoder().decode(M.self, from: $0) }
        }
    }
}

public extension Effect {
    func receive(on queue: DispatchQueue) -> Effect {
        return Effect { callback in
            run { a in
                queue.async {
                    callback(a)
                }
            }
        }
    }
}

public func dataTask(with url: URL) -> Effect<(Data?, URLResponse?, Error?)> {
    return Effect { callback in
        URLSession.shared.dataTask(with: url) { data, response, error in
            callback((data, response, error))
        }
        .resume()
    }
}
