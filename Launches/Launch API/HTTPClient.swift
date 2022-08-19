//
//  HTTPClient.swift
//  Launches
//
//  Created by Mert Vardar on 19.08.2022.
//

import Foundation

public enum HTTPClientResult {
    case success(HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
