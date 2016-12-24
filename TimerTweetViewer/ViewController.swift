//
//  ViewController.swift
//  TimerTweetViewer
//
//  Created by Keisei Saito on 2016/12/24.
//  Copyright © 2016 keisei_1092. All rights reserved.
//

import UIKit
import Accounts
import Social

final class ViewController: UIViewController {

    var accountStore: ACAccountStore = ACAccountStore()
    var twitterAccount: ACAccount?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        getAccounts()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getAccounts() { // 循環参照になってないかあとで見る
        let accountType: ACAccountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: accountType, options: nil) { (granted: Bool, error: Error?) -> Void in
            guard error == nil else {
                print("error! \(error)")
                return
            }
            guard granted else {
                print("error! Twitterアカウントの利用が許可されていません")
                return
            }

            let accounts = self.accountStore.accounts(with: accountType) as! [ACAccount]
            guard accounts.count != 0 else {
                print("error! 設定画面からアカウントを設定してください")
                return
            }
            print("アカウント取得完了")
        }
    }

}
