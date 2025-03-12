//
//  MathDetailViewController.swift
//  mathTest
//
//  Created by zhangz on 2025/1/20.
//

import UIKit
import WebKit
import Foundation

class MathDetailViewController: UIViewController {
    
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
    
    private let webView: WKWebView = {
        let webView = WKWebView()
        webView.backgroundColor = .white
        webView.scrollView.isScrollEnabled = false
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addMathExamples()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(mathScrollView)
        mathScrollView.frame = view.bounds
        mathScrollView.addSubview(contentStackView)
        
        contentStackView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: mathScrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: mathScrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: mathScrollView.trailingAnchor),
            contentStackView.widthAnchor.constraint(equalTo: mathScrollView.widthAnchor)
        ])
    }
    
    private func addMathExamples() {
        // 添加标题
        let titleLabel = UILabel()
        titleLabel.text = "数学公式示例"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .darkGray
        contentStackView.addArrangedSubview(titleLabel)
        
        // 示例4：使用WebView渲染更复杂的公式
        let complexLatex = "\\frac{d}{dx}\\left( \\int_{0}^{x} f(u),du\\right)=f(x)"
        NativeMathRenderHelper.addComplexMathFormula(
            to: contentStackView,
            latex: complexLatex,
            width: view.bounds.width - 40,
            height: 100
        )
    }
}
