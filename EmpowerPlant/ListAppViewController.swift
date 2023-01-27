//
//  ListAppViewController.swift
//  EmpowerPlant
//
//  Created by William Capozzoli on 3/8/22.
//

import UIKit
import Sentry

class ListAppViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        SentrySDK.capture(message: "Message from List App")

        // Do any additional setup after loading the view.
        do {
            try callMethodThatThrowsError()
        } catch let error as NSError {
            SentrySDK.capture(error: error) { (scope) in
                scope.setLevel(.fatal)
            }
        }
    }
    

    private func configureNavigationItems() {
        /*
     self.navigationItem.leftBarButtonItem = UIBarButtonItem(
         title: "Empower Plant",
         style: .plain,
         target: self,
         action: #selector(goToEmpowerPlant())
     )
     self.navigationItem.leftBarButtonItem?.tintColor = UIColor.blue
         */
    }

    
    func callMethodThatThrowsError() throws{
        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Handled Exception"])
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
