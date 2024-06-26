//
//  Service.swift
//
//
//  Created by Maciej Burdzicki on 21/04/2024.
//

import Foundation

public protocol Service {
    var baseUrl: URL { get }

    var requestBlocks: [String: RequestHandler] { get set }
    var responseBlocks: [String: ResponseHandler] { get set }

    init(baseUrl: URL)
}
