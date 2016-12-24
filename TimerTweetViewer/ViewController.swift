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
        getAccounts { (accounts: [ACAccount]) -> Void in
            self.showAccountSelectSheet(accounts: accounts) // この中でgetTimeLine()もされてる
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getAccounts(callback: @escaping ([ACAccount]) -> Void) { // 循環参照になってないかあとで見る
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
            callback(accounts)
        }
    }

    private func showAccountSelectSheet(accounts: [ACAccount]) {
        let alert = UIAlertController(title: "Twitter", message: "Choose an account", preferredStyle: .actionSheet)

        for account in accounts {
            alert.addAction(UIAlertAction(title: account.username, style: .default, handler: { [weak self] (action) -> Void in
                if let unwrapSelf = self {
                    unwrapSelf.twitterAccount = account
                    unwrapSelf.getTimeline()
                }
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func getTimeline() {
        let url = URL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json?count=20")
        guard let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, url: url, parameters: nil) else {
            return
        }
        request.account = twitterAccount
        request.perform { (responseData, response, error) -> Void in
            if error != nil {
                print(error ?? "error in performing request :[")
            } else {
                do {
                    guard let responseData = responseData else {
                        return
                    }
                    let result = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments)
                    for tweet in result as! [AnyObject] { // errorsが返ってくることがあるぞ
                        print(tweet["text"] as! String)
                    }
                }  catch let error as NSError {
                    print(error)
                }
            }
        }
    }

}
