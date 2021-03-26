import Cocoa
import ArgumentParser

/// An enum representing the badge's text type.
enum TextType: String, ExpressibleByArgument {
    case alpha, beta, version, build, versionAndBuild
}

/// An enum representing the ribbon position.
enum RibbonPosition: String, ExpressibleByArgument {
    case topLeft, topRight, bottomRight, bottomLeft
}

/// An enum representing the ribbon color.
enum RibbonColor: String, ExpressibleByArgument {
    case blue, cyan, gold, green, purple, red
}

/// Information about the running scrip context
protocol ScriptConfig: CustomStringConvertible {
    var verbose: Bool { get }
    var resourcesRootPath: String { get }
    var textVerticalBias: CGFloat { get }
    var infoPlistUrl: URL { get }
    var mainEnv: [String : String] { get }
}

// MARK: - Main command

struct IconBadger: ParsableCommand {
    
    // MARK: Configuration
    
    public static let configuration = CommandConfiguration(
        abstract: "A swift commad tools to manage badges for app icons",
        subcommands: [Target.self, Icon.self],
        defaultSubcommand: Target.self
    )
    
    // MARK: Options
    struct Options: ParsableArguments {
        
        @Option(name: .shortAndLong, help: ArgumentHelp(
            "The text to show on the badge. Possible values are : alpha, beta, version, build, versionAndBuild or your own custom text.",
            discussion: "If you choose alpha, beta, version, build or versionAndBuild make sure the script is executed as a build phase in Xcode"
        ))
        var text: String = ""
        
        @Option(help: "The text color in hex e.g #000000FF plus alpha (two last copmponents)")
        var textColor: String = "#FFFFFFFF"
        
        @Option(help: "The font to use for the text. This must be picked from the \"Font Book.app\" under \"PostScript name\"")
        var textFontName = "MarkerFelt-Thin"
        
        @Flag(help: "The text is going to be a mask cut off the ribbon to let show the icon background color")
        var textAsMask: Bool = false
        
        @Option(parsing: .unconditional, help: ArgumentHelp(
            "An optional value between -1.0 and 1.0 to fix an eventual vertical offset of the text. A value of 1.0 matches the ribbon height",
            discussion: "Depending on the choosen font the text might be a little bit vertically offset. This is due to the font metrics and how CoreGraphics handles drawing text.",
            valueName: "x"
        ))
        var textVerticalBias: Float = 0
        
        @Option(help: "The position of ribbon. Possible values are : topLeft, topRight, bottomRight or bottomLeft")
        var ribbonPosition: RibbonPosition = .bottomRight
        
        @Option(help: "The color of the ribbon to use. Possible values are : blue, cyan, gold, green, purple or red")
        var ribbonColor: RibbonColor = .cyan
        
        @Option(help: "Default path of the script root folder. It is not necessary to set when the script is executed as a build phase in Xcode")
        var resourcesRootPath: String?
        
        @Option(help: "Path of the \"Info.plist\" file of the current target. It is not necessary to set when the script is executed as a build phase in Xcode")
        var infoPlist: String?
        
        @Flag(name: .shortAndLong, help: "Show extra logging for debugging purposes")
        var verbose: Bool = false
        
        func validate() throws {
            guard textVerticalBias >= -1, textVerticalBias <= 1 else {
                throw ValidationError("Please provide a value between -1.0 and 1.0")
            }
        }
    }
}

// MARK: - Icon subcommand

extension IconBadger {
    
    struct Icon: ParsableCommand {
        
        /// Information about the running scrip context for the generate command
        public struct Config: ScriptConfig {
            let verbose: Bool
            let resourcesRootPath: String
            let textVerticalBias: CGFloat
            let infoPlistUrl: URL
            let mainEnv: [String : String]
            let inputFile: String
            let outputFile: String
            
            public var description: String {
                var aString = String(format: "%@ : %@\n", "resources root path".padded(toWidth: 40), resourcesRootPath)
                aString += String(format: "%@ : %.04f\n", "text vertical bias".padded(toWidth: 40), textVerticalBias)
                aString += String(format: "%@ : %@\n", "info plist file".padded(toWidth: 40), infoPlistUrl.path)
                aString += String(format: "%@ : %@\n", "input file".padded(toWidth: 40), inputFile)
                aString += String(format: "%@ : %@\n", "output file".padded(toWidth: 40), outputFile)
                return aString
            }
        }
        
        // MARK: Configuration
        
        public static let configuration = CommandConfiguration(abstract: "Generate an AppIcon with a badge from the given input icon according to the given options")
        
        // MARK: Options
        
        @OptionGroup
        private var options: IconBadger.Options
        
        @Option(name: .shortAndLong, help: "The path of the original icon to use in order to create the badged icon")
        var inputIcon: String
        
        @Option(name: .shortAndLong, help: "The path where the badged icon will be created")
        var outputIcon: String
        
        // MARK: Options validation
        
        func validate() throws {
            if options.text.isEmpty {
                throw ValidationError("Missing expected argument '--text <text>'")
            }
        }
        
        // MARK: Execute the command
        
        func run() throws {
            
            // make sure the color format is correct
            guard let color = NSColor(hex: options.textColor) else {
                print("Unable to read color from \(options.textColor)")
                Cocoa.exit(EXIT_FAILURE)
            }
            
            let config = getScriptConfig()
            let style = BadgeStyle(text: options.text, textColor: color, textFontName: options.textFontName, textAsMask: options.textAsMask,
                                   ribbonPosition: options.ribbonPosition, ribbonColor: options.ribbonColor)
            let badger = Badger(style: style, config: config)
            badger.processIcon()
        }
        
        private func getScriptConfig() -> Config {
            
            let env = ProcessInfo.processInfo.environment
            #if DEBUG
            let resourcesRootPath = "/Users/ach/dev/IconBadger"
            let plistPath = "/Users/ach/Downloads/Test/Test/Info.plist"
            #else
            // script resources root path
            let resourcesPath = options.resourcesRootPath ?? env["PODS_ROOT"]?.appendingPathComponent(path: "IconBadger")
            guard let resourcesRootPath = resourcesPath else {
                print("Missing required environment variable \"PODS_ROOT\". Please run the script from Xcode script build phase or use the option --resources-root-path")
                Cocoa.exit(EXIT_FAILURE)
            }
            // info.plist
            let filePath = options.infoPlist ?? env["INFOPLIST_FILE"]
            guard let plistPath = filePath else {
                print("Missing required environment variable \"INFOPLIST_FILE\". Please run the script from Xcode script build phase or use the option --info-plist")
                Cocoa.exit(EXIT_FAILURE)
            }
            #endif
            
            
            return Config(verbose: options.verbose,
                          resourcesRootPath: resourcesRootPath,
                          textVerticalBias: CGFloat(options.textVerticalBias),
                          infoPlistUrl: URL(fileURLWithPath: plistPath),
                          mainEnv: env,
                          inputFile: inputIcon, outputFile: outputIcon)
        }
    }
}

// MARK: - Traget subcommand

extension IconBadger {
 
    struct Target: ParsableCommand {
        
        /// Information about the running scrip context for the generate command
        public struct Config: ScriptConfig {
            let verbose: Bool
            let resourcesRootPath: String
            let textVerticalBias: CGFloat
            let infoPlistUrl: URL
            let mainEnv: [String : String]
            let appIconUrl: URL
            let appIconContents: IconMetadata
            let appIconOriginalUrl: URL
            let appIconOriginalContents: IconMetadata
            let restoreOriginal: Bool
            
            public var description: String {
                var aString = String(format: "%@ : %@\n", "resources root path".padded(toWidth: 40), resourcesRootPath)
                aString += String(format: "%@ : %.04f\n", "text vertical bias".padded(toWidth: 40), textVerticalBias)
                aString += String(format: "%@ : %@\n", "info plist file".padded(toWidth: 40), infoPlistUrl.path)
                aString += String(format: "%@ : %@\n", "app icon path".padded(toWidth: 40), appIconUrl.path)
                aString += String(format: "%@ : %02d\n", "app icon contents images count".padded(toWidth: 40), appIconContents.images.count)
                aString += String(format: "%@ : %@\n", "app icon original path".padded(toWidth: 40), appIconOriginalUrl.path)
                aString += String(format: "%@ : %02d\n", "app icon original contents images count".padded(toWidth: 40), appIconOriginalContents.images.count)
                aString += String(format: "%@ : %@\n", "restore original".padded(toWidth: 40), restoreOriginal ? "true" : "false")
                return aString
            }
        }
        
        // MARK: Configuration
        
        public static let configuration = CommandConfiguration(abstract: "Badge the AppIcon of the current target according to the given options when used from Xcode script build phase.")
        
        // MARK: Options
        
        @OptionGroup
        private var options: IconBadger.Options
        
        @Option(help: "The name of the AppIcon in the asset catalog which belongs to the current target")
        var appIcon: String = "AppIcon"
        
        @Option(help: "The name of the Original AppIcon (backup icon) in the asset catalog which belongs to the current target")
        var appIconOriginal: String = "AppIconOriginal"
        
        @Option(help: "The path of the Assets Catalog containing the AppIcon for the current target. If not specified the script will look for the first Assets Catalog in the project path which contains the specified AppIcon. This option is useful for example when you have multiple targets in your project and each target has its AppIcon in a seperate Assets Catalogs but named the same way.")
        var assetsCatalog: String?
        
        @Flag(help: "Use this flag to restore the original AppIcon, for instance for production build")
        var restoreOriginal: Bool = false
        
        // MARK: Options validation
        
        func validate() throws {
            if !restoreOriginal, options.text.isEmpty {
                throw ValidationError("Missing expected argument '--text <text>'")
            }
        }
        
        // MARK: Execute the command
        
        func run() throws {
            
            guard let color = NSColor(hex: options.textColor) else {
                print("Unable to read color from \(options.textColor)")
                Cocoa.exit(EXIT_FAILURE)
            }
            
            let config = getScriptConfig()
            let style = BadgeStyle(text: options.text, textColor: color,
                                   textFontName: options.textFontName, textAsMask: options.textAsMask,
                                   ribbonPosition: options.ribbonPosition, ribbonColor: options.ribbonColor)
            let badger = Badger(style: style, config: config)
            badger.processTarget()
        }
        
        private func getScriptConfig() -> Config {
            
            let env = ProcessInfo.processInfo.environment
            #if DEBUG
            let resourcesRootPath = "/Users/ach/dev/IconBadger"
            let projectDir = "/Users/ach/Downloads/Test"
            let plistPath = "/Users/ach/Downloads/Test/Test2/Info.plist"
            #else
            // script resources root path
            let resourcesPath = options.resourcesRootPath ?? env["PODS_ROOT"]?.appendingPathComponent(path: "IconBadger")
            guard let resourcesRootPath = resourcesPath else {
                print("Missing required environment variable \"PODS_ROOT\". Please run the script from Xcode script build phase or use the option --resources-root-path")
                Cocoa.exit(EXIT_FAILURE)
            }
            // info.plist
            let filePath = options.infoPlist ?? env["INFOPLIST_FILE"]
            guard let plistPath = filePath else {
                print("Missing required environment variable \"INFOPLIST_FILE\". Please run the script from Xcode script build phase or use the option --info-plist")
                Cocoa.exit(EXIT_FAILURE)
            }
            // project dir
            let projectDir = env["SRCROOT"] ?? ""
            if assetsCatalog == nil, env["SRCROOT"] == nil {
                print("Missing required environment variable \"SRCROOT\". Please run the script from Xcode script build phase or use the option --assets-catalog to provide the assets catalog path")
                Cocoa.exit(EXIT_FAILURE)
            }
            #endif
            
            var assetsCatalogUrl: URL!
            if let aPath = assetsCatalog {
                assetsCatalogUrl = URL(fileURLWithPath: aPath)
            } else {
                let url = URL(fileURLWithPath: projectDir)
                let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .nameKey, .parentDirectoryURLKey]
                if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles]) {
                    do {
                        for case let fileUrl as URL in enumerator {
                            let resourceValues = try fileUrl.resourceValues(forKeys: Set(resourceKeys))
                            if resourceValues.isDirectory == true, resourceValues.name == "\(appIcon).appiconset" {
                                assetsCatalogUrl = resourceValues.parentDirectory ?? fileUrl.deletingLastPathComponent()
                                break
                            }
                        }
                    } catch {
                        print("Unable to get resource values while trying to find the AppIcon assets")
                        Cocoa.exit(EXIT_FAILURE)
                    }
                } else {
                    print("Unable to list the project directory ")
                    Cocoa.exit(EXIT_FAILURE)
                }
            }
            
            let appIconUrl = assetsCatalogUrl.appendingPathComponent("\(appIcon).appiconset")
            let appIconOriginalUrl = assetsCatalogUrl.appendingPathComponent("\(appIconOriginal).appiconset")
            guard FileManager.default.fileExists(atPath: appIconOriginalUrl.path) else {
                print("\"\(appIconOriginal)\" not found. Please make sure to create a backup copy of the \"\(appIcon)\" in the same Aseets Catalog or use the option --app-icon-original if it is named differently")
                Cocoa.exit(EXIT_FAILURE)
            }
            
            do {
                let appIconContents = try Badger.iconMetadata(iconFolder: appIconUrl)
                let appIconOriginalContents = try Badger.iconMetadata(iconFolder: appIconOriginalUrl)
                return Config(verbose: options.verbose,
                              resourcesRootPath: resourcesRootPath,
                              textVerticalBias: CGFloat(options.textVerticalBias),
                              infoPlistUrl: URL(fileURLWithPath: plistPath),
                              mainEnv: env,
                              appIconUrl: appIconUrl, appIconContents: appIconContents,
                              appIconOriginalUrl: appIconOriginalUrl, appIconOriginalContents: appIconOriginalContents,
                              restoreOriginal: restoreOriginal)
            } catch {
                print("Impossible to read the content of the file \"Contents.json\" for the \(appIcon) or the \(appIconOriginal)")
                if options.verbose { print(error) }
                Cocoa.exit(EXIT_FAILURE)
            }
        }
    }
}

IconBadger.main()
