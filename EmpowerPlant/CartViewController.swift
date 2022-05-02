//
//  CartViewController.swift
//  EmpowerPlant
//
//  Created by William Capozzoli on 3/8/22.
//

import UIKit

class CartViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cart Screen"
        
        self.view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        // Comment this out and to see the green background and no data in the rows
        // tableView.frame = view.bounds
        
        configureNavigationItems()
        
        // TODO make this 'total' appear in a UI element
        print("CartViewController | TOTAL", ShoppingCart.instance.total)
    }
    
    private func configureNavigationItems() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Purchase",
            style: .plain,
            target: self,
            action: #selector(purchase)
        )
    }
    
    @objc
    func purchase() {
        print("purchase...")
        //print("> purchase!", ShoppingCart.instance.quantities.plantMood)
        //print("> purchase!", ShoppingCart.instance.quantities.botanaVoice)
        //print("> purchase!", ShoppingCart.instance.quantities.plantStroller)
        //print("> purchase!", ShoppingCart.instance.quantities.plantNodes)
        
        //let url = URL(string: "https://application-monitoring-flask-dot-sales-engineering-sf.appspot.com/checkout")!
        //let url = URL(string: "http://127.0.0.1:8080/success")!
        let url = URL(string: "http://127.0.0.1:8080/checkout")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        //struct Form : Codable {
        //    let email : String
        //}
        //let bodyTest = [Form(email: "will@chat.com")]
        /*
         cart.items
         cart.quantities
         cart.total
         form.email...
         */
        let body = ["user_id": "12"]
        //let body = ["form": { "email": "will@chat.com" }]
        let bodyData = try? JSONSerialization.data(
            withJSONObject: body,
            options: []
        )
        request.httpBody = bodyData
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            print("1 URLSession...")
            if let data = data {
                print("2 data", data)
//                if let response = try? JSONDecoder().decode([ProductMap].self, from: data) {
//                    
//                } else {
//                    print("Invalid Response")
//                }
            } else if let error = error {
                print("XXXXXX HTTP Request Failed \(error)")
            }
        }
        task.resume()
//        print("all over")

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // TODO could compute the length based on length of quantities.botanaVoice, plantStroller, nodeVoices, etc.
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
