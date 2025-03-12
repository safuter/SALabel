//
//  NativeMathDemoViewController.swift
//  mathTest
//
//  Created by Sarfuter on 2025/1/20.
//

import UIKit
import WebKit

class NativeMathDemoViewController: UIViewController {
    
    private let mathScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .white
        return scrollView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "原生数学公式渲染"
        view.backgroundColor = .white
        
        let testStr = """
   在债务重组中，甲公司通过转让专利技术来清偿其对乙公司的债务。根据会计处理原则，甲公司需要确认债务重组收益，并调整相关账户。以下是甲公司应编制的会计分录：

   1. 借记“应付账款”450万元，以消除债务；
   2. 借记“累计摊销”50万元，以转出已摊销的无形资产部分；
   3. 借记“无形资产减值准备”30万元，以转出已计提的减值准备；
   4. 贷记“无形资产”300万元，以转出无形资产的账面余额；
   5. 贷记“其他收益”230万元，以确认债务重组收益。

   具体的会计分录如下：


<table><tr><td>项目</td><td>金额</td></tr><tr><td>单价</td><td>60元/件</td></tr><tr><td>单位直接材料</td><td>20元/件</td></tr><tr><td>单位直接人工</td><td>8元/件</td></tr><tr><td>单位变动制造费用</td><td>16元/件</td></tr><tr><td>固定制造费用总额</td><td>180万元</td></tr><tr><td>单位变动销售和管理费用</td><td>2元/件</td></tr><tr><td>固定销售和管理费用总额</td><td>30万元</td></tr></table>

   $$
   \\begin{align*}
   \\text{借：应付账款} & \\quad 450\\,\\text{万元} \\\\  
   \\text{借：累计摊销} & \\quad 50\\,\\text{万元}  \\\\   
   \\text{借：无形资产减值准备} & \\quad 30\\,\\text{万元} \\\\   
   \\text{贷：无形资产} & \\quad 300\\,\\text{万元} \\\\  
   \\text{贷：其他收益} & \\quad 230\\,\\text{万元}  \\\\  
   \\end{align*}
   $$

   通过这笔分录，甲公司清偿了债务，并确认了由于债务重组产生的收益。继续努力学习，相信你会在会计实务中取得更好的成绩！
"""

        
        let str = SALabel.formulaReplace(testStr)
        let saLabel = SALabel(frame: CGRect(x: 30, y: 100, width: 520, height: 500))
        
        let stu = SALabel.extractTextStyle(str)
        
        saLabel.setComponentsAndPlainText(stu)
        saLabel.frame = CGRect(x: 30, y: 100, width: saLabel.optimumSize().width, height: saLabel.optimumSize().height)
        view.addSubview(saLabel)
    }
}
