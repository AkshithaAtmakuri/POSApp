//
//  ProductViewController.swift
//  PredictSpring
//
//  Created by Akshitha atmakuri on 19/01/24.
//

import UIKit
import SVProgressHUD

class ProductViewController: UIViewController {
    var statusLabel: UILabel!
    var fileProcessingPercentageLabel: UILabel!
    var downloadButton: UIButton!
    var searchBar: UISearchBar!
    var tableView: UITableView!
    var productViewModel = ProductViewModel()
    var progressView: UIProgressView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        self.title = "POS Search"
        
        statusLabel = UILabel()
        statusLabel.text = "In order to do a Product search, please click the download button."
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        fileProcessingPercentageLabel = UILabel()
        fileProcessingPercentageLabel.text = "0%"
        fileProcessingPercentageLabel.numberOfLines = 0
        fileProcessingPercentageLabel.textAlignment = .center
        fileProcessingPercentageLabel.translatesAutoresizingMaskIntoConstraints = false
        fileProcessingPercentageLabel.font = .boldSystemFont(ofSize: 28)
        view.addSubview(fileProcessingPercentageLabel)
        
        downloadButton = UIButton(type: .system)
        downloadButton.setTitle("Download", for: .normal)
        downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(downloadButton)
        
        searchBar = UISearchBar()
        searchBar.placeholder = "Search by product id or name"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        view.addSubview(searchBar)
        
        tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProductCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        searchBar.isHidden = true
        tableView.isHidden = true
        progressView.isHidden = true
        fileProcessingPercentageLabel.isHidden = true
        
        setupConstraints()
        
        productViewModel.onProductsUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        
        productViewModel.onFileDownloadProgress = { progress in
            SVProgressHUD.showProgress(progress, status: "Downloading...")
        }
        
        productViewModel.onProgressUpdate = { [weak self] progress in
            DispatchQueue.main.async {
                self?.statusLabel.isHidden = false
                self?.progressView.progress = progress
                self?.fileProcessingPercentageLabel.text = "\(Int(progress * 100))%"
            }
        }
        
        productViewModel.onParsingStart = { [weak self] in
            DispatchQueue.main.async {
                self?.progressView.isHidden = false
                self?.statusLabel.isHidden = false
                self?.statusLabel.text = "Processing the file..."
                self?.fileProcessingPercentageLabel.text = "0%"
                self?.fileProcessingPercentageLabel.isHidden = false
            }
        }
        
        productViewModel.onFileProcessingCompletion = { [weak self] in
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                self?.statusLabel.isHidden = true
                self?.downloadButton.isHidden = true
                self?.fileProcessingPercentageLabel.isHidden = true
                self?.progressView.isHidden = true
                self?.searchBar.isHidden = false
                self?.tableView.isHidden = false
                self?.tableView.reloadData()
                let alert = UIAlertController(title: "File Processing Completed", message: "You can now start searching for products.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        NSLayoutConstraint.activate([
            downloadButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            downloadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            progressView.heightAnchor.constraint(equalToConstant: 10)
        ])
        
        NSLayoutConstraint.activate([
            fileProcessingPercentageLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),
            fileProcessingPercentageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            fileProcessingPercentageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    @objc private func downloadButtonTapped() {
        statusLabel.isHidden = true
        downloadButton.isHidden = true
        searchBar.isHidden = true
        tableView.isHidden = true
        
        SVProgressHUD.showProgress(0.0, status: "Downloading...")
        
        if let url = URL(string: URLConstants.fileDownload) {
            productViewModel.downloadFileFromServer(url: url)
        }
    }
}

extension ProductViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productViewModel.filteredProducts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath)
        if let product = productViewModel.getProduct(at: indexPath.row)  {
            // Configure cell with product information
            cell.textLabel?.text = "\(product.title) - \(product.size)"
            cell.detailTextLabel?.text = "\(product.listPrice) - \(product.salesPrice)"
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        
        if offsetY > contentHeight - scrollView.frame.size.height {
            productViewModel.loadMoreProducts()
        }
    }
}

extension ProductViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        productViewModel.filterProducts(searchText: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

