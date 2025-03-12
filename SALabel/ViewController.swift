//
//  ViewController.swift
//  mathTest
//
//  Created by zhangz on 2025/1/20.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "MathJax渲染示例"
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "原生数学公式渲染示例"
        }
        let lb = UILabel()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let detailVC = MathDetailViewController()
            self.navigationController?.pushViewController(detailVC, animated: true)
        } else if indexPath.row == 1 {
            let nativeVC = NativeMathDemoViewController()
            self.navigationController?.pushViewController(nativeVC, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let tb = UITableView(frame: .init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height), style: .plain)
        view.addSubview(tb)
        
        tb.delegate = self
        tb.dataSource = self

        
    }

}

