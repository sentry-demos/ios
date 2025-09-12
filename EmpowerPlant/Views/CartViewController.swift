//
//  CartViewController.swift
//  EmpowerPlant
//
//  Created by William Capozzoli on 3/8/22.
//

import UIKit
import Sentry

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
}

protocol URLSessionDataTaskProtocol {
    func resume()
}

class CartViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //private let session: URLSessionProtocol

    let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    // Used for mocking in unit test
    init(session: URLSessionProtocol = URLSession.shared as! URLSessionProtocol) {
        //self.session = session
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cart Screen"

        self.view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        configureNavigationItems()
        checkRelease()

        // TODO: make this 'total' appear in a UI element
        print("CartViewController | TOTAL", ShoppingCart.instance.total)
        SentrySDK.reportFullyDisplayed()
    }

    private func configureNavigationItems() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Purchase",
            style: .plain,
            target: self,
            action: #selector(purchase)
        )
        self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "Purchase"
    }

    @objc
    func purchase() {
        let logger = SentrySDK.logger
        logger.info("Purchase initiated", attributes: [
            "cartTotal": ShoppingCart.instance.total,
            "itemCount": ShoppingCart.instance.items.count
        ])
        
        // use localhost for development against dev-backend
        // let url = URL(string: "http://127.0.0.1:8080/checkout")!
        let url = URL(string: "https://application-monitoring-flask-dot-sales-engineering-sf.appspot.com/checkout")!


        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        let bodyData = try? JSONSerialization.data(
            withJSONObject: setJson(),
            options: []
        )
        request.httpBody = bodyData

        enum PurchaseError: Error, LocalizedError {
            case insufficientInventory
            
            var errorDescription: String? {
                switch self {
                case .insufficientInventory:
                    return "Insufficient inventory available"
                }
            }
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            let logger = SentrySDK.logger
            
            // This handler is responsible for Flagship Error
            if let httpResponse = response as? HTTPURLResponse {
                if (httpResponse.statusCode) == 500 {
                    let err = PurchaseError.insufficientInventory
                    logger.error("Purchase failed with server error", attributes: [
                        "statusCode": 500,
                        "errorType": "insufficient_inventory"
                    ])
                    ErrorToastManager.shared.logErrorAndShowToast(
                        error: err,
                        message: "Purchase failed: Insufficient inventory available (HTTP 500)",
                        showFeedbackOption: true  // Enable User Feedback for checkout errors
                    )
                } else if (httpResponse.statusCode) == 200 {
                    logger.info("Purchase completed successfully", attributes: [
                        "statusCode": 200,
                        "cartTotal": ShoppingCart.instance.total
                    ])
                } else {
                    logger.warn("Purchase completed with unexpected status", attributes: [
                        "statusCode": httpResponse.statusCode
                    ])
                }
            }

            // not getting met
            // if let error = error {
            //    print("> HTTP Request Failed \(error)")
            //    SentrySDK.capture(error: error)
            //}

            // getting met whether it's a 200 or 500 - there's always a 'data' object here
            // if let data = data {
            //     print("> no error, do nothing", data)
            //}
        }

        task.resume()
    }

    // total, quantities, items
    func setJson() -> [String: Any] {

        // total DONE
        // quantities DONE below
        // TODO: items

        let json: [String: Any] = [
            "form": ["email":"will@example.com"], // TODO: email update + check if all tx's+errors have email
            "cart": [
                "total": ShoppingCart.instance.total,
                "quantities": [
                    "3": ShoppingCart.instance.quantities.plantMood,
                    "4": ShoppingCart.instance.quantities.botanaVoice,
                    "5": ShoppingCart.instance.quantities.plantStroller,
                    "6": ShoppingCart.instance.quantities.plantNodes,
                ],
                "items": [
                    ["id":"4", "title":"Plant Nodes"]
                    // ["id":"5", "title":"Plant Stroller"]
                ]
            ],
            "validate_inventory": "true"
        ]

        return json
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // TODO: could compute the length based on length of quantities.botanaVoice, plantStroller, nodeVoices, etc.
        // or continue showing all products, even if quantity is 0. the screen looks more full this way
        return 4 // products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //  'product' here has all available attributes here, if needed in the future (e.g. UI development)
        // let product = products[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        var items: [Int] = [
            ShoppingCart.instance.quantities.plantMood,
            ShoppingCart.instance.quantities.botanaVoice,
            ShoppingCart.instance.quantities.plantStroller,
            ShoppingCart.instance.quantities.plantNodes,
        ]

        var text = ""
        var quantity = items[indexPath.row]

        switch indexPath.row {
        case 0:
            text = "Plant Mood: " + String(quantity)
            break
        case 1:
            text = "Botana Voice: " + String(quantity)
            break
        case 2:
            text = "Plant Stroller: " + String(quantity)
            break
        case 3:
            text = "Plant Nodes: " + String(quantity)
            break
        default:
            print("indexPath.row was not 0,1,2,3")
        }

        cell.textLabel?.text = text

        return cell
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
