//
//  AppDelegate.swift
//  TVGuide
//
//  Created by Jason Jobe on 12/10/15.
//  Copyright © 2015 WildThink. All rights reserved.
//
import Foundation
import AppKit
import XCPlayground

//XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

class ODB: NSObject {

    let baseUrl = NSURL(string: "http://www.omdbapi.com")!
    var useTomatoes = true

    func fetch (query: String, callback: (AnyObject?) -> Void)
    {
        let url = NSURL(string: "\(query)", relativeToURL:baseUrl)!
        let request = NSMutableURLRequest(URL: url)
        let urlSession = NSURLSession.sharedSession()
        
        let task = urlSession.dataTaskWithRequest(request,
            completionHandler: {(data, response, error) -> Void in
                
                var result: AnyObject?
                
                if error != nil {
                    print(error!.localizedDescription)
                }
                else if data != nil {
                    try! result = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
                }
                callback (result)
        })
        task.resume()
    }

    func search (terms: String, callback: (NSArray) -> Void)
    {
        let keywords = terms.stringByReplacingOccurrencesOfString(" ", withString: "+",
            options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)

        self.fetch("?s=\(keywords)&r=json") { (result) -> Void in
            if let dict = result as? NSDictionary {
                callback ((dict["Search"] as? NSArray)!)
            }
        }
    }
    
    func fetchDetails (id: String, callback: (NSDictionary?) -> Void) {
        let tomatoes =  useTomatoes ? "&tomatoes=true" : ""
        self.fetch("?i=\(id)&plot=full&r=json\(tomatoes)") { (results) -> Void in
            callback (results as? NSDictionary)
        }
    }
}

struct Text : StringInterpolationConvertible
{
    enum Style { case H1, P, Tab, Integer, Real }
    enum Mark { case H1(AnyObject), P(AnyObject), Tab, Integer(Int), Real(Double) }

    var actualString: String!
    var components = [Mark]()
    
    init<T>(stringInterpolationSegment expr: T) {
        actualString = String(expr)
        components.append(.P(expr as! AnyObject))
    }
    
    init(stringInterpolation strings: Text...) {
        actualString = (strings.map { $0.actualString }) .joinWithSeparator("")
        for str in strings {
            components.appendContentsOf(str.components)
        }
    }
    
    init (stringInterpolationSegment expr: Mark) {
        actualString = "\(expr)"
        components.append(expr)
    }

    init (stringInterpolationSegment expr: Int) {
        actualString = "\(expr)"
        components.append(.Integer(expr))
    }

    init (stringInterpolationSegment expr: Double) {
        actualString = "\(expr)"
        components.append(.Real(expr))
    }
}

extension NSMutableAttributedString {

    func append (string: String) {
        self.appendAttributedString(NSAttributedString(string: string))
    }
}

class Textyle {
    
    static let numberFormatter: NSNumberFormatter = {
        let fmtr = NSNumberFormatter()
        fmtr.numberStyle = .DecimalStyle
        return fmtr
    }()

    var numberFormatter: NSNumberFormatter {
        get {
            return Textyle.numberFormatter
        }
    }
    
    func attributedString (text: Text) -> NSAttributedString
    {
        let attributed_string =  NSMutableAttributedString()
        
        for item in text.components {
            print (item)
            switch item {
                case .H1(let any):
                    var attributes = [String: AnyObject]()
                    attributes[NSFontAttributeName] = NSFont(name: "Chalkduster", size: 18.0)!
                    attributes[NSUnderlineStyleAttributeName] = true
                    let str = "\(any)\n"
                    attributed_string.appendAttributedString(NSAttributedString(string: str, attributes: attributes))
                case .P(let any):
                    attributed_string.append(any.description)
                case .Integer(let any):
                    attributed_string.append(numberFormatter.stringFromNumber(any)!)
                case .Real(let any):
                    attributed_string.append(numberFormatter.stringFromNumber(any)!)
                case .Tab:
                    attributed_string.append("\t")
            }
        }
        return attributed_string
    }
}

//////////////
// Try it out

let db = ODB()

db.search("dog mad") { (shows) -> Void in
    for show in shows {
        print (show)
    }
}

db.fetchDetails("tt0156812") { (info: NSDictionary?) -> Void in
    print (info)
}

var t: Text = "\(.H1("Title"))Time is \(2345.98)"
t.actualString
t.components

let stylesheet = Textyle()
var astr = stylesheet.attributedString(t)
astr.string
