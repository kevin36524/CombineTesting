//: [Previous](@previous)

import Foundation
import Combine


var str = "Hello, playground"

enum Endpoints {
    case getCount
    case incrementCount
    case getCountWithFailureRateLatency(Int, Int)
    
    static let rootURL = "https://us-central1-fbconfig-90755.cloudfunctions.net"
    var url: URL? {
        switch self {
        case .getCount:
            return URL(string: "\(Self.rootURL)/swiftUIGetCounter")
        case .incrementCount:
            return URL(string: "\(Self.rootURL)/swiftUIUpdateCounter")
        case.getCountWithFailureRateLatency(let failureRate, let latency):
            return URL(string: "\(Self.rootURL)/swiftUIGetCounter?failureRate=\(failureRate)&delay=\(latency)")
        }
    }
}

struct SyncCountResult: Codable {
    struct Result:  Codable{
        let count: Int
    }
    var result: Result
}

enum NetworkErr: Error {
    case unknown
    case urlFormationError
    case serverErr
    case enCodingError
}

var cancelBag = Set<AnyCancellable>()


let getCountPub =
    Just(Endpoints.getCountWithFailureRateLatency(50, 0).url)
    .flatMap{ (url) -> AnyPublisher<Result<SyncCountResult,  NetworkErr>,Never> in
        if let url = url {
            return publisherForURL(url:url)
        }
        return Just(Result<SyncCountResult, NetworkErr>.failure(.urlFormationError)).eraseToAnyPublisher()
    }
    
    
func publisherForURL<T:Codable>(url: URL) -> AnyPublisher<Result<T, NetworkErr>, Never>  {
    return URLSession.shared.dataTaskPublisher(for: url)
        .tryMap({ (data, response) -> T in
            guard let response = response as? HTTPURLResponse else {
                throw NetworkErr.unknown
            }
            
            if response.statusCode != 200 {
                throw NetworkErr.serverErr
            }
            
            guard let res = try? JSONDecoder().decode(T.self, from: data) else  {
                throw NetworkErr.enCodingError
            }
            
            return res
        })
        .print("URLPUB")
        .map{
            Result<T, NetworkErr>.success($0)
        }
        .mapError { (err) -> NetworkErr in
            if let err = err as? NetworkErr {
                return err
            }
            return NetworkErr.unknown
        }
        .retry(2)
        .catch { (err) -> Just<Result<T, NetworkErr>> in
            Just(Result<T, NetworkErr>.failure(err))
        }.eraseToAnyPublisher()

}
    
getCountPub
    .sink { (res) in
        print("Got the network result \(res)")
    }.store(in: &cancelBag)
    
//: [Next](@next)

