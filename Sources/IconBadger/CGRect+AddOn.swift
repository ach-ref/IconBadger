//
//  CGRect+AddOn.swift
//  IconBadger
//
//  Created by iOS Developer on 18/3/21.
//

import Foundation

extension NSRect {
    
    /// Alias for origin.x.
    public var x: CGFloat {
        get {return origin.x}
        set {origin.x = newValue}
    }
    /// Alias for origin.y.
    public var y: CGFloat {
        get {return origin.y}
        set {origin.y = newValue}
    }
    
    /// Accesses origin.x + 0.5 * size.width.
    public var centerX: CGFloat {
        get {return minX + width * 0.5}
        set {x = newValue - width * 0.5}
    }
    
    /// Accesses origin.y + 0.5 * size.height.
    public var centerY: CGFloat {
        get {return y + height * 0.5}
        set {y = newValue - height * 0.5}
    }
    
    /// Accesses the point at the center.
    public var center: CGPoint {
        get {return CGPoint(x: centerX, y: centerY)}
        set {centerX = newValue.x; centerY = newValue.y}
    }
    
    /// Returns a rect of the specified size centered in this rect.
    public func center(size: CGSize) -> CGRect {
        let dx = width - size.width
        let dy = height - size.height
        return CGRect(x: minX + dx * 0.5, y: minY + dy * 0.5, width: size.width, height: size.height)
    }
}
