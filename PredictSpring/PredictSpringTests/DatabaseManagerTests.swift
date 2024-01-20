//
//  DatabaseManagerTests.swift
//  PredictSpringTests
//
//  Created by Akshitha atmakuri on 19/01/24.
//

import XCTest
@testable import PredictSpring

class DatabaseManagerTests: XCTestCase {
    
    func testDatabaseInitialization() {
        XCTAssertNotNil(DatabaseManager.shared)
    }
    
    func testInsertProducts() {
        let databaseManager = DatabaseManager.shared
        let product = Product(productId: "1", title: "Test Product", listPrice: 10.0, salesPrice: 8.0, color: "Red", size: "M")
        databaseManager.insertProducts(products: [product])
        let insertedProducts = databaseManager.getProducts(searchText: "Test Product", page: 1, pageSize: 1)
        XCTAssertEqual(insertedProducts.count, 1)
        XCTAssertEqual(insertedProducts.first?.productId, product.productId)
        XCTAssertEqual(insertedProducts.first?.title, product.title)
        XCTAssertEqual(insertedProducts.first?.listPrice, product.listPrice)
        XCTAssertEqual(insertedProducts.first?.salesPrice, product.salesPrice)
        XCTAssertEqual(insertedProducts.first?.color, product.color)
        XCTAssertEqual(insertedProducts.first?.size, product.size)
    }
    
    func testGetProducts() {
        let databaseManager = DatabaseManager.shared
        let searchText = "Test"
        let products = databaseManager.getProducts(searchText: searchText, page: 1, pageSize: 10)
        XCTAssertEqual(products.count, 0)
    }
}


