/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class MainViewController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var loadingView: UIView!
  @IBOutlet weak var emptyView: UIView!
  @IBOutlet weak var errorLabel: UILabel!
  @IBOutlet weak var errorView: UIView!
  
  let searchController = UISearchController(searchResultsController: nil)
  let networkingService = NetworkingService()
  let darkGreen = UIColor(red: 11/255, green: 86/255, blue: 14/255, alpha: 1)
  var recordings: [Recording]?
  var error: Error?
  var isLoading = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Chirper"
    activityIndicator.color = darkGreen
    prepareNavigationBar()
    prepareSearchBar()
    prepareTableView()
    loadRecordings()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    searchController.searchBar.becomeFirstResponder()
  }
  
  // MARK: - Loading recordings
  
  @objc func loadRecordings() {
    isLoading = true
    tableView.tableFooterView = loadingView
    recordings = []
    tableView.reloadData()
    
    let query = searchController.searchBar.text
    networkingService.fetchRecordings(matching: query, page: 1) { [weak self] response in
      
      guard let `self` = self else {
        return
      }
      
      self.searchController.searchBar.endEditing(true)
      self.isLoading = false
      self.update(response: response)
    }
  }

  func update(response: RecordingsResult) {
    if let recordings = response.recordings, !recordings.isEmpty {
      tableView.tableFooterView = nil
    } else if let error = response.error {
      errorLabel.text = error.localizedDescription
      tableView.tableFooterView = errorView
      tableView.reloadData()
      return
    } else {
      tableView.tableFooterView = emptyView
    }
    
    recordings = response.recordings
    error = response.error
    tableView.reloadData()
  }
  
  // MARK: - View Configuration
  
  func prepareSearchBar() {
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.delegate = self
    searchController.searchBar.autocapitalizationType = .none
    searchController.searchBar.autocorrectionType = .no
    
    searchController.searchBar.tintColor = .white
    searchController.searchBar.barTintColor = .white
    
    let whiteTitleAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.white]
    let textFieldInSearchBar = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
    textFieldInSearchBar.defaultTextAttributes = whiteTitleAttributes
    
    navigationItem.searchController = searchController
    searchController.searchBar.becomeFirstResponder()
  }
  
  func prepareNavigationBar() {
    navigationController?.navigationBar.barTintColor = darkGreen
    
    let whiteTitleAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
    navigationController?.navigationBar.titleTextAttributes = whiteTitleAttributes
  }
  
  func prepareTableView() {
    tableView.dataSource = self
    
    let nib = UINib(nibName: BirdSoundTableViewCell.NibName, bundle: .main)
    tableView.register(nib, forCellReuseIdentifier: BirdSoundTableViewCell.ReuseIdentifier)
  }
  
}

// MARK: -

extension MainViewController: UISearchBarDelegate {
  
  func searchBar(_ searchBar: UISearchBar,
                 selectedScopeButtonIndexDidChange selectedScope: Int) {
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    NSObject.cancelPreviousPerformRequests(withTarget: self,
                                           selector: #selector(loadRecordings),
                                           object: nil)
    
    perform(#selector(loadRecordings), with: nil, afterDelay: 0.5)
  }
  
}

extension MainViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    return recordings?.count ?? 0
  }
  
  func tableView(_ tableView: UITableView,
                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: BirdSoundTableViewCell.ReuseIdentifier)
      as? BirdSoundTableViewCell else {
        return UITableViewCell()
    }
    
    if let recordings = recordings {
      cell.load(recording: recordings[indexPath.row])
    }
    
    return cell
  }
}

