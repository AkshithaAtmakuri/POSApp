//
//  ProductViewModelTests.swift
//  PredictSpringTests
//
//  Created by Akshitha atmakuri on 19/01/24.
//

import XCTest
@testable import PredictSpring

class ProductViewModelTests: XCTestCase {
    
    var viewModel: ProductViewModel!
    let mockURL = URL(string: "https://drive.usercontent.google.com/uc?id=16jxfVYEM04175AMneRlT0EKtaDhhdrrw")!
    let errorMockURL = URL(string: "https://drive.usercontent.google.com/uc?id=16jxfVYEM04175AMneRlT0EKtaDhhdrrw")!
    var mockDatabaseManager: MockDatabaseManager!
    
    override func setUp() {
        super.setUp()
        viewModel = ProductViewModel()
        mockDatabaseManager = MockDatabaseManager()
        viewModel.databaseManager = mockDatabaseManager
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testInsertProductsToDatabase() {
        let initialCount = DatabaseManager.shared.getProducts(searchText: "", page: 1, pageSize: 20).count
        let newProduct = Product(productId: "3", title: "New Product", listPrice: 20.0, salesPrice: 18.0, color: "Green", size: "Large")
        DatabaseManager.shared.insertProducts(products: [newProduct])
        let finalCount = DatabaseManager.shared.getProducts(searchText: "", page: 1, pageSize: 20).count
        XCTAssertEqual(initialCount + 1, finalCount)
    }
    
    func testDownloadFileFromServer() {
        let mockURL = URL(string: "https://example.com/mockfile.csv")!
        viewModel.downloadFileFromServer(url: mockURL)
        XCTAssertNotNil(viewModel.downloadTask)
    }
    
    func testFileParsingFailure() {
        let parsingFailureMockURL = URL(fileURLWithPath: "parsingFailureMockFilePath")
        viewModel.parseDownloadedFile(at: parsingFailureMockURL)
        XCTAssertTrue(viewModel.filteredProducts.isEmpty)
        XCTAssertFalse(mockDatabaseManager.didCallInsertProducts)
        XCTAssertNil(viewModel.onFileProcessingCompletion)
    }
    
    func testDownloadFailure() {
        viewModel.downloadFileFromServer(url: mockURL)
        XCTAssertTrue(viewModel.filteredProducts.isEmpty)
        XCTAssertFalse(mockDatabaseManager.didCallGetProducts)
        XCTAssertNil(viewModel.onFileDownloadProgress)
    }
    
    func testParseDownloadedFile_EmptyFile() {
        let emptyMockURL = URL(fileURLWithPath: "emptyMockFilePath")
        viewModel.parseDownloadedFile(at: emptyMockURL)
        XCTAssertEqual(viewModel.filteredProducts.count, 0)
        XCTAssertFalse(mockDatabaseManager.didCallInsertProducts)
    }
    
    func testParseDownloadedFile_ErrorHandling() {
        let errorMockURL = URL(fileURLWithPath: "errorMockFilePath")
        viewModel.parseDownloadedFile(at: errorMockURL)
        XCTAssertFalse(mockDatabaseManager.didCallInsertProducts)
        XCTAssertEqual(viewModel.filteredProducts, [])
    }
    
    func testDownloadFileFromServer_Error() {
        viewModel.downloadFileFromServer(url: errorMockURL)
        XCTAssertFalse(mockDatabaseManager.didCallGetProducts)
        XCTAssertEqual(viewModel.filteredProducts, [])
    }
    
    func testFilterProducts_EmptySearchText() {
        viewModel.filterProducts(searchText: "")
        XCTAssertEqual(viewModel.filteredProducts.count, 0)
        XCTAssertFalse(mockDatabaseManager.didCallGetProducts)
    }
    
    func testFilterProducts_NonEmptySearchText() {
        viewModel.filterProducts(searchText: "test")
        XCTAssertTrue(mockDatabaseManager.didCallGetProducts)
    }
    
    func testLoadMoreProducts_EmptySearchText() {
        viewModel.currentSearchText = ""
        viewModel.loadMoreProducts()
        XCTAssertFalse(mockDatabaseManager.didCallGetProducts)
    }
    
    func testLoadMoreProducts_NonEmptySearchText() {
        viewModel.currentSearchText = "test"
        viewModel.loadMoreProducts()
        XCTAssertTrue(mockDatabaseManager.didCallGetProducts)
    }
    
}
