//
//  ProductViewModel.swift
//  PredictSpring
//
//  Created by Akshitha atmakuri on 19/01/24.
//

import Foundation
import CSV
import SVProgressHUD

class ProductViewModel: NSObject {
    var filteredProducts: [Product] = []
    var onProductsUpdate: (() -> Void)?
    var onFileDownloadProgress: ((Float) -> Void)?
    var onFileProcessingCompletion: (() -> Void)?
    var onProgressUpdate: ((Float) -> Void)?
    var onParsingStart: (() -> Void)?
    
    var downloadTask: URLSessionDownloadTask!
    var databaseManager = DatabaseManager.shared
    
    private var currentPage = 1
    private let pageSize = 20
    var currentSearchText: String = ""
    
    func parseDownloadedFile(at url: URL) {
        let filePath = url.path
        onParsingStart?()
        do {
            let totalRows = try countLines(filePath: filePath)
            onProgressUpdate?(0.0)
            let stream = InputStream(fileAtPath: filePath)!
            let csv = try CSVReader(stream: stream)
            var rowCount = 0
            var productsToStore: [Product] = []
            
            while let row = csv.next() {
                let product = Product(
                    productId: row[0] ,
                    title: row[1] ,
                    listPrice: Double(row[2] ) ?? 0.0,
                    salesPrice: Double(row[3] ) ?? 0.0,
                    color: row[4] ,
                    size: row[5]
                )
                productsToStore.append(product)
                rowCount += 1
                if rowCount % 1000 == 0 {
                    storeProductsInDatabase(products: productsToStore)
                    productsToStore.removeAll()
                }
                let progress = Float(rowCount) / Float(totalRows)
                onProgressUpdate?(progress)
            }
            onFileProcessingCompletion?()
        } catch {
            print("Error reading or parsing file: \(error)")
        }
    }
    
    func downloadFileFromServer(url: URL) {
        SVProgressHUD.show(withStatus: "Downloading...")
        let task = URLSession.shared.downloadTask(with: url) { [weak self] (tempLocalUrl, response, error) in
            guard let self = self else { return }
            SVProgressHUD.dismiss()
            if let error = error {
                print("Error downloading file: \(error)")
                SVProgressHUD.showError(withStatus: "Download failed")
                return
            }
            
            guard let tempLocalUrl = tempLocalUrl else {
                SVProgressHUD.showError(withStatus: "Download failed")
                return
            }
            
            do {
                let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let destinationUrl = documentsDirectory.appendingPathComponent("downloadedFile.csv")
                
                do {
                    try FileManager.default.removeItem(at: destinationUrl)
                } catch {
                }
                try FileManager.default.moveItem(at: tempLocalUrl, to: destinationUrl)
                self.parseDownloadedFile(at: destinationUrl)
            } catch {
                print("Error moving or parsing file: \(error)")
                SVProgressHUD.showError(withStatus: "Download failed")
            }
        }
        self.downloadTask = task
        task.progress.addObserver(self, forKeyPath: "fractionCompleted", options: .new, context: nil)
        task.resume()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "fractionCompleted", let progress = (object as? Progress)?.fractionCompleted else { return }
        onFileDownloadProgress?(Float(progress))
    }
    
    private func countLines(filePath: String) throws -> Int {
        let contents = try String(contentsOfFile: filePath)
        let lines = contents.components(separatedBy: .newlines)
        return lines.count
    }
    
    func getProduct(at index: Int) -> Product? {
        guard index >= 0 && index < filteredProducts.count else {
            return nil
        }
        return filteredProducts[index]
    }
    
    private func storeProductsInDatabase(products: [Product]) {
        databaseManager.insertProducts(products: products)
    }
    
    func filterProducts(searchText: String) {
        guard !searchText.isEmpty  else {
            currentSearchText = searchText
            filteredProducts = [Product]()
            onProductsUpdate?()
            return
        }
        currentSearchText = searchText
        currentPage = 1
        let products = databaseManager.getProducts(searchText: searchText, page: currentPage, pageSize: pageSize)
        filteredProducts = products
        onProductsUpdate?()
    }
    
    func loadMoreProducts() {
        if !currentSearchText.isEmpty {
            currentPage += 1
            let products = databaseManager.getProducts(searchText: currentSearchText, page: currentPage, pageSize: pageSize)
            filteredProducts.append(contentsOf: products)
            onProductsUpdate?()
        }
    }
    
    deinit {
        if downloadTask != nil {
            downloadTask.progress.removeObserver(self, forKeyPath: "fractionCompleted")
        }
    }
}

