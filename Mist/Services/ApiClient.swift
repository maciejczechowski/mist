//
//  ApiClient.swift
//  Mist
//
//  Created by Maciej Czechowski on 24.10.2018.
//  Copyright © 2018 Maciej Czechowski. All rights reserved.
//

import Foundation
import RxSwift

protocol ApiClientProtocol {
    func getAndParseResponse<T: Codable>(t: T.Type, for path: String) -> Observable<T>
}

class ApiClient {
    let baseUrl: URL

    init(with baseUrl: URL) {
        self.baseUrl = baseUrl
    }

    func getAndParseResponse<T: Codable>(t: T.Type, for path: String) -> Observable<T> {
      
            guard let components = URLComponents(url: self.baseUrl.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
                fatalError("Unable to create URL components")
            }
            
            guard let url = components.url else {
                fatalError("Could not get url")
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Accept")
           
            return URLSession
                .shared
                .rx
                .data(request: request)
                .map{ data in
                    let model: T = try JSONDecoder().decode(T.self, from: data )
                    return model;
        }
            
        
        
    }
}
