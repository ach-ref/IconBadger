//
//  String+Path.swift
//  IconBadger
//
//  Created by iOS Developer on 18/3/21.
//

import Foundation

// MARK: - Path
public extension String {
    
    func appendingPathComponent(path: String) -> String {
        return (self as NSString).appendingPathComponent(path)
    }
    
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
    
    var deletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }
}

// MARK: - Padding
public extension String {
    
    func padded(toWidth width: Int, pad: String = " ") -> String {
        return self.padding(toLength: width, withPad: pad, startingAt: 0)
    }
}
