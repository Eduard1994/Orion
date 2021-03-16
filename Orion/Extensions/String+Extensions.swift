//
//  String+Extensions.swift
//  Orion
//
//  Created by Eduard Shahnazaryan on 3/15/21.
//

import Foundation
import UIKit

public struct Strings {}

class BundleClass {}

func OrionLocalizedString(_ key: String, tableName: String? = nil, value: String = "", comment: String) -> String {
    let bundle = Bundle(for: BundleClass.self)
    return NSLocalizedString(key, tableName: tableName, bundle: bundle, value: value, comment: comment)
}

extension Strings {
    public static let DownloadProgressToastDescriptionText = OrionLocalizedString("Downloads.Toast.Progress.DescriptionText", value: "%1$@/%2$@", comment: "The description text in the Download progress toast for showing the downloaded file size (1$) out of the total expected file size (2$).")
    public static let DownloadMultipleFilesToastDescriptionText = OrionLocalizedString("Downloads.Toast.MultipleFiles.DescriptionText", value: "1 of %d files", comment: "The description text in the Download progress toast for showing the number of files when multiple files are downloading.")
    public static let DownloadMultipleFilesAndProgressToastDescriptionText = OrionLocalizedString("Downloads.Toast.MultipleFilesAndProgress.DescriptionText", value: "%1$@ %2$@", comment: "The description text in the Download progress toast for showing the number of files (1$) and download progress (2$). This string only consists of two placeholders for purposes of displaying two other strings side-by-side where 1$ is Downloads.Toast.MultipleFiles.DescriptionText and 2$ is Downloads.Toast.Progress.DescriptionText. This string should only consist of the two placeholders side-by-side separated by a single space and 1$ should come before 2$ everywhere except for right-to-left locales.")
    public static let CancelDownloadDialogMessage = OrionLocalizedString("Downloads.CancelDialog.Message", value: "Are you sure you want to cancel this download?", comment: "Alert dialog body when the user taps the cancel download icon.")
    public static let CancelDownloadDialogTitle = OrionLocalizedString("Downloads.CancelDialog.Title", value: "Cancel Download", comment: "Alert dialog title when the user taps the cancel download icon.")
    public static let CancelDownloadDialogResume = OrionLocalizedString("Downloads.CancelDialog.Resume", value: "Resume", comment: "Button declining the cancellation of the download.")
    public static let CancelDownloadDialogCancel = OrionLocalizedString("Downloads.CancelDialog.Cancel", value: "Cancel", comment: "Button confirming the cancellation of the download.")
    public static let DownloadCancelledToastLabelText = OrionLocalizedString("Downloads.Toast.Cancelled.LabelText", value: "Download Cancelled", comment: "The label text in the Download Cancelled toast for showing confirmation that the download was cancelled.")
    public static let DownloadsButtonTitle = OrionLocalizedString("Downloads.Toast.GoToDownloads.Button", value: "Downloads", comment: "The button to open a new tab with the Downloads home panel")
    public static let DownloadFailedToastLabelText = OrionLocalizedString("Downloads.Toast.Failed.LabelText", value: "Download Failed", comment: "The label text in the Download Failed toast for showing confirmation that the download has failed.")
    public static let UnableToAddPassErrorTitle = OrionLocalizedString("AddPass.Error.Title", value: "Failed to Add Pass", comment: "Title of the 'Add Pass Failed' alert. See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorMessage = OrionLocalizedString("AddPass.Error.Message", value: "An error occured while adding the pass to Wallet. Please try again later.", comment: "Text of the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorDismiss = OrionLocalizedString("AddPass.Error.Dismiss", value: "OK", comment: "Button to dismiss the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
}

public extension String {
    func escape() -> String? {
        // We can't guaruntee that strings have a valid string encoding, as this is an entry point for tainted data,
        // we should be very careful about forcefully dereferencing optional types.
        // https://stackoverflow.com/questions/33558933/why-is-the-return-value-of-string-addingpercentencoding-optional#33558934
        let queryItemDividers = CharacterSet(charactersIn: "?=&")
        let allowedEscapes = CharacterSet.urlQueryAllowed.symmetricDifference(queryItemDividers)
        return self.addingPercentEncoding(withAllowedCharacters: allowedEscapes)
    }

    func unescape() -> String? {
        return self.removingPercentEncoding
    }

    /**
    Ellipsizes a String only if it's longer than `maxLength`

      "ABCDEF".ellipsize(4)
      // "AB…EF"

    :param: maxLength The maximum length of the String.

    :returns: A String with `maxLength` characters or less
    */
    func ellipsize(maxLength: Int) -> String {
        if (maxLength >= 2) && (self.count > maxLength) {
            let index1 = self.index(self.startIndex, offsetBy: (maxLength + 1) / 2) // `+ 1` has the same effect as an int ceil
            let index2 = self.index(self.endIndex, offsetBy: maxLength / -2)

            return String(self[..<index1]) + "…\u{2060}" + String(self[index2...])
        }
        return self
    }

    private var stringWithAdditionalEscaping: String {
        return self.replacingOccurrences(of: "|", with: "%7C")
    }

    var asURL: URL? {
        // Firefox and NSURL disagree about the valid contents of a URL.
        // Let's escape | for them.
        // We'd love to use one of the more sophisticated CFURL* or NSString.* functions, but
        // none seem to be quite suitable.
        return URL(string: self) ??
               URL(string: self.stringWithAdditionalEscaping)
    }

    /// Returns a new string made by removing the leading String characters contained
    /// in a given character set.
    func stringByTrimmingLeadingCharactersInSet(_ set: CharacterSet) -> String {
        var trimmed = self
        while trimmed.rangeOfCharacter(from: set)?.lowerBound == trimmed.startIndex {
            trimmed.remove(at: trimmed.startIndex)
        }
        return trimmed
    }

    /// Adds a newline at the closest space from the middle of a string.
    /// Example turning "Mark as Read" into "Mark as\n Read"
    func stringSplitWithNewline() -> String {
        let mid = self.count / 2

        let arr: [Int] = self.indices.compactMap {
            if self[$0] == " " {
                return self.distance(from: startIndex, to: $0)
            }

            return nil
        }
        guard let closest = arr.enumerated().min(by: { abs($0.1 - mid) < abs($1.1 - mid) }) else {
            return self
        }
        var newString = self
        newString.insert("\n", at: newString.index(newString.startIndex, offsetBy: closest.element))
        return newString
    }

    static func contentsOfFileWithResourceName(_ name: String, ofType type: String, fromBundle bundle: Bundle, encoding: String.Encoding, error: NSErrorPointer) -> String? {
        return bundle.path(forResource: name, ofType: type).flatMap {
            try? String(contentsOfFile: $0, encoding: encoding)
        }
    }

    func remove(_ string: String?) -> String {
        return self.replacingOccurrences(of: string ?? "", with: "")
    }

    func replaceFirstOccurrence(of original: String, with replacement: String) -> String {
        guard let range = self.range(of: original) else {
            return self
        }

        return self.replacingCharacters(in: range, with: replacement)
    }
    
    func isEmptyOrWhitespace() -> Bool {
        // Check empty string
        if self.isEmpty {
            return true
        }
        // Trim and check empty string
        return (self.trimmingCharacters(in: .whitespaces) == "")
    }
    
    /// Handles logic to make part of string bold
    /// - Parameters:
    ///     - boldString: the portion of the string that should be bold. Current string must already include this string.
    ///     - font: font for entire string, part of string will be converted to bold version of this font
    func attributedText(boldString: String, font: UIFont) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self,
                                                     attributes: [NSAttributedString.Key.font: font])
        let boldFontAttribute: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: font.pointSize)]
        let range = (self as NSString).range(of: boldString)
        attributedString.addAttributes(boldFontAttribute, range: range)
        return attributedString
    }
}

/// Duplicate a string n number of times.
///
/// - Parameters:
///   - lhs: The string to duplicate
///   - rhs: The number of times to duplicate the string
/// - Returns: The resulting string
func * (lhs: String, rhs: Int) -> String {
    guard rhs > 0 else { return "" }
    
    var result = ""
    for _ in 0..<rhs {
        result += lhs
    }
    
    return result
}

extension String {
    func isURL() -> Bool {
        if self.hasPrefix("https://") || self.hasPrefix("http://") {
            return true
        }
        
        return self.range(of: "^(https?:\\/\\/)?([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([\\/\\w \\.-]*)*\\/?$", options: .regularExpression) != nil
    }
    
    var lines: [String] {
        var result: [String] = []
        enumerateLines { line, _ in result.append(line) }
        return result
    }
    
    func countLeadingSpaces() -> Int {
        guard !isEmpty else { return 0 }
        
        var i = startIndex
        var count = 0
        while i < endIndex {
            let c = self[i]
            if c == " " {
                count += 1
            } else {
                break
            }
            i = self.index(i, offsetBy: 1)
        }
        
        return count
    }
    
    func getIndentationLevel(tabSize: Int) -> Int {
        guard tabSize > 0 else { return 0 }
        
        let formattedString = self.replacingOccurrences(of: "\t", with: " " * tabSize)
        
        return formattedString.countLeadingSpaces() / tabSize
    }
}
