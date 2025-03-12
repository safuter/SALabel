# SALabel

SALabel is a high-performance rich text rendering library for iOS that provides native HTML parsing and complex content display capabilities.

## Features

- **Native HTML Rich Text Parsing**: Efficiently parse and render HTML content with full styling support
- **Complex Content Support**:
  - Tables rendering with customizable layouts
  - Image display with automatic sizing and caching
  - LaTeX formula rendering with MathML support
  - Custom content embedding capabilities
- **Text Interaction**:
  - Text selection and copying
  - Link detection and handling
  - Custom touch area configuration
- **High Performance**:
  - Efficient text rendering using Core Text
  - Optimized image loading and caching
  - Smooth scrolling and interaction
- **Customization**:
  - Text alignment and line break modes
  - Font and color styling
  - Background and stroke customization
  - Link appearance configuration

## Requirements

- iOS 13.0+
- Xcode 12.0+

## Installation

### CocoaPods

```ruby
pod 'SALabel'
```

## Basic Usage

```objective-c
#import "SALabel.h"

// Create and configure SALabel
SALabel *label = [[SALabel alloc] initWithFrame:frame];

// Set attributed text with styling
NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"Your text"];
label.attributedText = attributedString;

// Configure text properties
label.textAlignment = RTTextAlignmentLeft;
label.lineBreakMode = RTTextLineBreakModeWordWrapping;

// Add to view hierarchy
[self.view addSubview:label];
```

## Advanced Features

### LaTeX Formula Rendering

SALabel supports rendering LaTeX formulas using the integrated Math rendering engine:

```objective-c
// LaTeX formula example
NSString *formula = @"\\[E = mc^2\\]";
RTLabelComponentsStructure *components = [SALabel extractTextStyle:tableHTML];
[label setComponentsAndPlainText:components];
```

### Table Support

```objective-c
// HTML table example
NSString *tableHTML = @"<table><tr><td>Cell 1</td><td>Cell 2</td></tr></table>";
RTLabelComponentsStructure *components = [SALabel extractTextStyle:tableHTML];
[label setComponentsAndPlainText:components];
```

### Image Handling



## License

SALabel is available under the MIT license. See the LICENSE file for more info.

## Author

Sarfuter Zhang <sarfuter@gmail.com>

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
