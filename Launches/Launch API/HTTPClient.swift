//
//  HTTPClient.swift
//  Launches
//
//  Created by Mert Vardar on 19.08.2022.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void)
}
