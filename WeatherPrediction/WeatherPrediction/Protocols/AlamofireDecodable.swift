//
//  AlamofireDecodable.swift
//  WeatherPrediction
//
//  Created by Octav Stanciu on 09.03.2025.
//

import Alamofire
import Foundation

protocol AlamofireDecodable { }

extension AlamofireDecodable {
    func decode<D>(_ type: D.Type, from data: Data) throws -> D where D : Decodable {
        let decoder = JSONDecoder()
        return try decoder.decode(D.self, from: data)
    }
}
