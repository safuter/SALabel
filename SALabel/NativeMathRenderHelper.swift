//
//  NativeMathRenderHelper.swift
//  mathTest
//
//  Created by Sarfuter on 2025/1/20.
//

import UIKit
import WebKit

@objc class NativeMathRenderHelper: NSObject {
    
    // MARK: - HTML 富文本渲染方法
    
    /// 创建一个HTML富文本WebView
    /// - Parameters:
    ///   - html: HTML内容
    ///   - width: WebView宽度
    ///   - height: WebView高度
    /// - Returns: 配置好的WKWebView
    @objc static func createHTMLView(
        html: String,
        width: CGFloat,
        height: CGFloat
    ) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .white
        webView.scrollView.isScrollEnabled = false
        webView.loadHTMLString(html, baseURL: nil)
        
        webView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        return webView
    }
    
    /// 将HTML富文本添加到容器视图中
    /// - Parameters:
    ///   - container: 容器视图
    ///   - html: HTML内容
    ///   - width: WebView宽度
    ///   - height: WebView高度
    /// - Returns: 创建的WebView
    @objc @discardableResult
    static func addHTMLView(
        to container: UIStackView,
        html: String,
        width: CGFloat,
        height: CGFloat = 200
    ) -> WKWebView {
        let webView = createHTMLView(html: html, width: width, height: height)
        container.addArrangedSubview(webView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.widthAnchor.constraint(equalToConstant: width),
            webView.heightAnchor.constraint(equalToConstant: height)
        ])
        
        return webView
    }
    
    /// 创建包含MathJax的HTML内容，用于在WebView中渲染复杂的LaTeX公式
    /// - Parameter latex: LaTeX公式
    /// - Returns: 包含MathJax的HTML字符串
    @objc static func createMathJaxHTML(latex: String) -> String {
        return """
        <html>
        <head>
            <meta name='viewport' content='width=device-width, initial-scale=1'>
            <script type='text/javascript' async src='https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js?config=TeX-MML-AM_CHTML'></script>
            <script type="text/x-mathjax-config">
                MathJax.Hub.Config({
                    tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]},
                    messageStyle: "none",
                    showMathMenu: false,
                    "HTML-CSS": { 
                        linebreaks: { automatic: true },
                        scale: 100,
                        styles: {
                            ".MathJax_Display": {margin: 0}
                        }
                    }
                });
            </script>
            <style>
                body {
                    font-family: -apple-system;
                    margin: 0;
                    padding: 10px;
                    font-size: 16px;
                }
            </style>
        </head>
        <body>
            $$\\displaystyle \(latex)$$
        </body>
        </html>
        """.replacingOccurrences(of: "\(latex)", with: latex)
    }
    
    /// 将LaTeX公式渲染为WebView（用于复杂公式）
    /// - Parameters:
    ///   - container: 容器视图
    ///   - latex: LaTeX格式的数学公式
    ///   - width: WebView宽度
    ///   - height: WebView高度
    /// - Returns: 创建的WebView
    @objc @discardableResult
    static func addComplexMathFormula(
        to container: UIStackView,
        latex: String,
        width: CGFloat,
        height: CGFloat = 200
    ) -> WKWebView {
        let html = createMathJaxHTML(latex: latex)
        return addHTMLView(to: container, html: html, width: width, height: height)
    }
    
    /// 创建富文本字符串
    /// - Parameters:
    ///   - text: 文本内容
    ///   - font: 字体
    ///   - textColor: 文本颜色
    /// - Returns: NSAttributedString
    @objc static func createAttributedString(
        text: String,
        font: UIFont = .systemFont(ofSize: 16),
        textColor: UIColor = .black
    ) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    /// 将HTML转换为AttributedString
    /// - Parameter html: HTML字符串
    /// - Returns: NSAttributedString?
    @objc static func attributedStringFromHTML(html: String) -> NSAttributedString? {
        guard let data = html.data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data,
                                         options: [.documentType: NSAttributedString.DocumentType.html,
                                                  .characterEncoding: String.Encoding.utf8.rawValue],
                                         documentAttributes: nil)
        } catch {
            print("Error converting HTML to AttributedString: \(error)")
            return nil
        }
    }
}
