//
//  MockDatabaseManager.swift
//  PredictSpringTests
//
//  Created by Akshitha atmakuri on 19/01/24.
//


import Foundation
@testable import PredictSpring

class MockDatabaseManager: DatabaseManager {
    var didCallInsertProducts = false
    var mockStoredProducts: [Product] = []
    var didCallGetProducts = false
    
    override internal init() {
        super.init()
    }
    
    override func insertProducts(products: [Product]) {
        didCallInsertProducts = true
        mockStoredProducts = products
        super.insertProducts(products: products)
    }
    
    override func getProducts(searchText: String, page: Int, pageSize: Int) -> [Product] {
        didCallGetProducts = true
        return mockStoredProducts
    }
}


