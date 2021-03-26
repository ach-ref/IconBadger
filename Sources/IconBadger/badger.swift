//
//  Badger.swift
//  IconBadger
//
//  Created by iOS Developer on 18/3/21.
//

import Cocoa

let kJsonContentsFileName = "Contents.json"
let KRibbonWidthFactor: CGFloat = 283 / 450
let KRibbonHeightFactor: CGFloat = 87.68 / 450
let π: CGFloat = .pi

// MARK: - Conf

/// Style of the Badge
public struct BadgeStyle: CustomStringConvertible {
    let text: String
    let textColor: NSColor
    let textFontName: String
    let textAsMask: Bool
    let ribbonPosition: RibbonPosition
    let ribbonColor: RibbonColor
    
    public var description: String {
        var aString = String(format: "%@ : %@\n", "text".padded(toWidth: 40), text)
        aString += String(format: "%20@ : %@\n", "text color".padded(toWidth: 40), textColor)
        aString += String(format: "%20@ : %@\n", "font name".padded(toWidth: 40), textFontName)
        aString += String(format: "%20@ : %@\n", "text as mask".padded(toWidth: 40), textAsMask ? "true" : "false")
        aString += String(format: "%20@ : %@\n", "ribbon position".padded(toWidth: 40), ribbonPosition.rawValue)
        aString += String(format: "%20@ : %@\n", "ribbon color".padded(toWidth: 40), ribbonColor.rawValue)
        return aString
    }
    
    func ribbonImage(config: ScriptConfig) -> NSImage {
        let ribbonFileName = "\(ribbonColor)-\(ribbonPosition).png"
        let baseDir = config.resourcesRootPath.appendingPathComponent(path: "resources/ribbons")
        let ribbonPath = baseDir.appendingPathComponent(path: ribbonFileName)
        guard let image = NSImage(contentsOfFile: ribbonPath) else {
            print("Could not read ribbon file located at \(ribbonPath)")
            exit(EXIT_FAILURE)
        }
        
        return image
    }
}

// MARK: - Image JSON structs

/// Structure of Contents.json
struct IconMetadata: Decodable {
    
    var images: [ImageInfo]
    
    func imageInfo(forSize size: String, scale: String, idiom: String) -> ImageInfo? {
        for image in images {
            if image.size == size, image.scale == scale, image.idiom == idiom {
                return image
            }
        }
        return nil
    }
}

/// Image description structure
struct ImageInfo: Decodable {
    var size: String
    var idiom: String
    var filename: String?
    var scale: String
}

public struct Badger {
    
    // MARK: - Properties
    
    let style: BadgeStyle
    let config: ScriptConfig
    
    // MARK: - Image processing
    
    private func generateBadgeImage(maxWidth: CGFloat, maxHeight: CGFloat) -> NSImage {
        // vars
        let drawText = getText(text: style.text, config: config)
        let xPadding = maxWidth * 0.1
        var textFontSize = maxWidth * 0.15
        
        // make sure we can handle the font name
        guard let _ = NSFont(name: style.textFontName, size: textFontSize) else {
            print("Can't get the font named \(style.textFontName). Please make sure the font exists in the \"Font Book.app\"")
            exit(EXIT_FAILURE)
        }
        
        // text shadow
        let shadow = NSShadow()
        shadow.shadowColor = .black
        shadow.shadowBlurRadius = 5
        shadow.shadowOffset = .zero
        // text attributes
        var textAttributes: [NSAttributedString.Key : Any] = [
            .font: NSFont(name: style.textFontName, size: textFontSize)!,
            .foregroundColor: style.textColor,
            .shadow: shadow
        ]
        
        // badge image
        let badgeImage = NSImage(size: NSSize(width: maxWidth, height: maxHeight), flipped: false) { rect -> Bool in
            // draw the ribbon image first
            let ribbonWidth = KRibbonWidthFactor * maxWidth
            let ribbonHeight = KRibbonHeightFactor * maxHeight
            let ribbonImage = style.ribbonImage(config: config)
            ribbonImage.draw(in: rect)
            
            guard let context = NSGraphicsContext.current?.cgContext else {
                print("Unable to get the current image context while trying to generate the badge image")
                exit(EXIT_FAILURE)
            }
            
            var textSize = drawText.size(withAttributes: textAttributes)
            while (textSize.width > ribbonWidth - xPadding || textSize.height > ribbonHeight) {
                textFontSize -= 0.25
                textAttributes[NSAttributedString.Key.font] = NSFont(name: style.textFontName, size: textFontSize)!
                textSize = drawText.size(withAttributes: textAttributes)
            }
            
            // badge rect
            var rotateBy = π/4
            let dx = maxWidth * 0.2745
            let dy = maxHeight * 0.2745
            var badgeRect = rect.center(size: CGSize(width: ribbonWidth, height: ribbonHeight))
            switch style.ribbonPosition {
            case .topLeft:
                badgeRect.center.x -= dx
                badgeRect.center.y += dy
            case .topRight:
                rotateBy = -rotateBy
                badgeRect.center.x += dx
                badgeRect.center.y += dy
            case .bottomRight:
                badgeRect.center.x += dx
                badgeRect.center.y -= dy
            case .bottomLeft:
                rotateBy = -rotateBy
                badgeRect.center.x -= dx
                badgeRect.center.y -= dy
            }
            
            context.translateBy(x: badgeRect.center.x, y: badgeRect.center.y)
            context.rotate(by: rotateBy)
            context.translateBy(x: -badgeRect.center.x, y: -badgeRect.center.y)
            
            var textRect = badgeRect.center(size: textSize)
            let bias = config.textVerticalBias * ribbonHeight
            textRect.origin.y += bias
            if style.textAsMask { context.setBlendMode(.destinationOut) }
            drawText.draw(in: textRect, withAttributes: textAttributes)

            return true
        }
        
        
        
        return badgeImage
    }
    
    private func generateOutputImage(source inputFile: String) -> NSImage {
        
        guard let inputIcon = NSImage(contentsOfFile: inputFile) else {
            print("Could not read input file located at \(inputFile)")
            exit(EXIT_FAILURE)
        }
        
        let cgimage = inputIcon.cgImage(forProposedRect: nil, context: nil, hints: nil)
        let realWidth = cgimage == nil ? inputIcon.size.width : CGFloat(cgimage!.width)
        let realHeight = cgimage == nil ? inputIcon.size.height : CGFloat(cgimage!.height)
        
        // debug print
        if config.verbose {
            print("Generating the badge image...")
        }
        
        let badgeIcon = generateBadgeImage(maxWidth: realWidth, maxHeight: realHeight)
        
        // debug print
        if config.verbose {
            print("Merging the badge image with the app icon...")
        }
        
        let outputImage = NSImage(size: CGSize(width: realWidth, height: realHeight), flipped: false) { rect -> Bool in
            inputIcon.draw(in: rect)
            badgeIcon.draw(in: rect)
            return true
        }
        
        return outputImage
    }
    
    // MARK: - Public
    
    func processIcon() {
        // make sure we got the right config
        guard let config = config as? IconBadger.Icon.Config else {
            print("Wrong configuration for the running script")
            exit(EXIT_FAILURE)
        }
        
        // debug print
        if config.verbose {
            print("Config ===================================")
            print(config)
            print("Style ====================================")
            print(style)
        }
        
        let outputImage = generateOutputImage(source: config.inputFile)
        
        // debug print
        if config.verbose {
            print("Copying the generated icon to the destination path...")
        }
        
        writeImageFile(image: outputImage, filePath: config.outputFile)
        
        // debug print
        if config.verbose {
            print("Success ✅")
        }
        
        exit(EXIT_SUCCESS)
    }
    
    func processTarget() {
        // make sure we got the right config
        guard let config = config as? IconBadger.Target.Config else {
            print("Wrong configuration for the running script")
            exit(EXIT_FAILURE)
        }
        
        // debug print
        if config.verbose {
            print("Config ===================================")
            print(config)
            print("Style ====================================")
            print(style)
        }
        
        for image in config.appIconOriginalContents.images {
            generateIcon(config: config, size: image.size, scale: image.scale, idiom: image.idiom, restore: config.restoreOriginal)
        }
        
        exit(EXIT_SUCCESS)
    }
    
    // MARK: - Helpers
    
    private func generateIcon(config: IconBadger.Target.Config, size: String, scale: String, idiom: String, restore: Bool) {
        // retreive the original file name according to the given size and scale
        guard let originalFileName = config.appIconOriginalContents.imageInfo(forSize: size, scale: scale, idiom: idiom)?.filename else {
            print("The original icon \"\(idiom)\" size \"\(size)\" and scale \"\(scale)\" doesn't exist")
            print("Discarded ⚠️\n")
            return
        }
        
        // retreive the destination file name according to the given size and scale
        guard let destinationFileName = config.appIconContents.imageInfo(forSize: size, scale: scale, idiom: idiom)?.filename else {
            print("The app icon \"\(idiom)\" size \"\(size)\" and scale \"\(scale)\" doesn't exist")
            print("Discarded ⚠️\n")
            return
        }
        
        // get files URLs
        let originalFileUrl = config.appIconOriginalUrl.appendingPathComponent(originalFileName)
        let destinationFileUrl = config.appIconUrl.appendingPathComponent(destinationFileName)
        
        // generate the badged icon
        guard restore else {
            // debug print
            if config.verbose {
                print(originalFileUrl.lastPathComponent)
                print("Generating badge image for \"\(idiom)\" size \"\(size)\" scale \"\(scale)\"")
            }
            
            let outPutIcon = generateOutputImage(source: originalFileUrl.path)
            
            // debug print
            if config.verbose {
                print("Copying the generated icon to the destination path...")
            }
            
            writeImageFile(image: outPutIcon, filePath: destinationFileUrl.path)
            
            // debug print
            if config.verbose {
                print("Success ✅\n")
            }
            
            return
        }
        
        // debug print
        if config.verbose {
            print(originalFileUrl.lastPathComponent)
            print("Restoring the original image \"\(idiom)\" size \"\(size)\" scale \"\(scale)\"")
        }
        
        // restore the original icon
        writeImageFile(originalFileUrl, toUrl: destinationFileUrl)
        
        // debug print
        if config.verbose {
            print("Success ✅\n")
        }
    }
    
    private func writeImageFile(image: NSImage, filePath: String) {
        
        if let data = image.tiffRepresentation, let png = NSBitmapImageRep(data: data)?.representation(using: .png, properties: [:]) {
            do {
                try NSData(data: png).write(toFile: filePath, options: [.atomic])
            } catch {
                print("Error while saving image to disk at \(filePath)")
                if config.verbose { print(error) }
                exit(EXIT_FAILURE)
            }
        }
    }
    
    private func writeImageFile(_ imageFile: URL, toUrl destination: URL) {
        do {
            let data = try Data(contentsOf: imageFile)
            try data.write(to: destination, options: [.atomic])
        } catch {
            print("Error while copying image at \(imageFile.path) to \(destination.path)")
            if config.verbose { print(error) }
            exit(EXIT_FAILURE)
        }
    }
    
    private func getText(text: String, config: ScriptConfig) -> String {
        if let type = TextType(rawValue: text) {
            switch type {
            case .alpha, .beta: return text.capitalized
            case .version, .build, .versionAndBuild:
                guard let infoDict = NSDictionary(contentsOfFile: config.infoPlistUrl.path) else {
                    print("Unable to read the content of \(config.infoPlistUrl.lastPathComponent)")
                    exit(EXIT_FAILURE)
                }
                
                var version = infoDict["CFBundleShortVersionString"] as? String
                var build = infoDict["CFBundleVersion"] as? String
                version = version == "$(MARKETING_VERSION)" ? config.mainEnv["MARKETING_VERSION"] : version
                build = build == "$(CURRENT_PROJECT_VERSION)" ? config.mainEnv["CURRENT_PROJECT_VERSION"] : build
                
                guard let appVersion = version, let buildNumber = build else {
                    print("Missing required environment variables \"MARKETING_VERSION\" and/or \"CURRENT_PROJECT_VERSION\". Please run script from Xcode script build phase or enter the Version/Build numbers manually.")
                    exit(EXIT_FAILURE)
                }
                
                if type == .version {
                    return appVersion
                } else if type == .build {
                    return buildNumber
                } else {
                    return "\(appVersion) - \(buildNumber)"
                }
            }
        } else {
            return text
        }
    }
    
    // MARK: - Static
    
    /// Getting information about the app icon images
    static func iconMetadata(iconFolder: URL) throws -> IconMetadata {
        let fileUrl = iconFolder.appendingPathComponent(kJsonContentsFileName)
        do {
            let jsonData =  try Data(contentsOf: fileUrl)
            let metadata = try JSONDecoder().decode(IconMetadata.self, from: jsonData)
            return metadata
        } catch {
            print("An error occured while trying to get the app's icons metadata from the file located at \"\(fileUrl.path)\"")
            exit(EXIT_FAILURE)
        }
    }
}

