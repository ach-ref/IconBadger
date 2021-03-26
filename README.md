# IconBadger

A script adding dynamically a badge with a custom text to an app's icon on build time.
<br/>
<br/>

<p align="center">
    <a href="#"><img src="https://img.shields.io/badge/Swift-5.0-orange" /></a>
    <a href="https://cocoapods.org/pods/IconBadger"><img src="https://img.shields.io/cocoapods/v/IconBadger" /></a>
    <a href="https://cocoapods.org/pods/IconBadger"><img src="https://img.shields.io/cocoapods/p/IconBadger" /></a>
    <a href="https://cocoapods.org/pods/IconBadger"><img src="https://img.shields.io/cocoapods/l/IconBadger" /></a>
</p>

<p align="center">
    <a href="#features">Features</a> ⦿ 
    <a href="#requirements">Requirements</a> ⦿ 
    <a href="#installation">Installation</a> ⦿ 
    <a href="#usage">Usage</a> ⦿ 
    <a href="#author">Author</a> ⦿ 
    <a href="#license">License</a>
</p>

<br/>
<p align="center">
    <img src="https://raw.githubusercontent.com/ach-ref/IconBadger/main/resources/images/custom-text.png" />
    <img src="https://raw.githubusercontent.com/ach-ref/IconBadger/main/resources/images/beta.png" />
    <img src="https://raw.githubusercontent.com/ach-ref/IconBadger/main/resources/images/version-and-build.png" />
    <img src="https://raw.githubusercontent.com/ach-ref/IconBadger/main/resources/images/alpha.png" />
</p>

A script written in Swift that can dynamically add an icon overlay with a custom text such as alpha, beta or the app version number on the top of a ribbon image. IconBadger will resize the text to dynamically fit inside the ribbon. This script uses Core Graphics and no dependencies such as ImageMagick. The icon overlay can be customized in many ways. This project is highly inspired by both <a target="_blank" href="https://github.com/DanielCech/VersionIcon">VersionIcon</a> and <a target="_blank" href="https://github.com/jorystiefel/stampicon">stampicon</a> i combined both ideas into one to answer a need i had for a multi-targets big project.

## [Features](#features)

* ✅ Writen in Swift 5
* ✅ Fully customizable
* ✅ Works in both Swift and Objective-C projects
* ✅ No dependencies
* ✅ Dynamically badge the icon during build time

## [Requirements](#requirements)

* iOS 9.0 and later
* Xcode 10.0 and later

## [Installation](#installation)

Using Cocoapods, you can install it if it is not installed yet

```bash
$ gem install cocoapods
```
1dd IconBadger to your project

```ruby
pod 'IconBadger', '~> 1.0'
```
Then run the install command

```bash
$ pod install
```

## [Usage](#usage)

There is twoo ways to use IconBadger : add badge to an icon or add badge to a target (all icons of the current target). In both cases you need to

1. Create a copy of your AppIcon in the same assets catalog. For example if your app icon is named AppIcon, create a copy called AppIconOriginal. This copy will be used when you want to restore the original app icon without any badge on it - for instance for the production builds.

2. Create a `New Run Script Phase` in `Build Phases` tab in Xcode

3. You can use this example and adjuts it if you have different configuration
```bash
if [ "${CONFIGURATION}" = "Release" ]; then
    "Pods/IconBadger/resources/bin/iconBadger" --restore-original
else
    "Pods/IconBadger/resources/bin/iconBadger" target -t "versionAndBuild" --text-as-mask --ribbon-position bottomRight --ribbon-color cyan --verbose
fi
```

4. Move the script just above the `Copy Bunble Resources Phase`

Below all the parameters for both subcommands, for help you can run `iconBadger help`

### Icon subcommand
```bash
$ iconBadger help icon

OVERVIEW: Generate an AppIcon with a badge from the given input icon according to the given options

USAGE: icon-badger icon [--text <text>] [--text-color <text-color>] [--text-font-name <text-font-name>] [--text-as-mask] [--text-vertical-bias <x>] [--ribbon-position <ribbon-position>] [--ribbon-color <ribbon-color>] [--resources-root-path <resources-root-path>] [--info-plist <info-plist>] [--verbose] --input-icon <input-icon> --output-icon <output-icon>

OPTIONS:
  -t, --text <text>       The text to show on the badge. Possible values are : alpha, beta, version, build, versionAndBuild 
                          or your own custom text. If you choose alpha, beta, version, build or versionAndBuild make sure the script is executed as a build phase in Xcode
  --text-color <text-color>
                          The text color in hex e.g "#000000FF" plus alpha (two last copmponents) (default: "#FFFFFFFF")
  --text-font-name <text-font-name>
                          The font to use for the text. This must be picked from the "Font Book.app" under "PostScript name" (default: MarkerFelt-Thin)
  --text-as-mask          The text is going to be a mask cut off the ribbon to let show the icon background color 
  --text-vertical-bias <x>
                          An optional value between -1.0 and 1.0 to fix an eventual vertical offset of the text. A value of 1.0 matches the ribbon height (default: 0.0)
                          Depending on the choosen font the text might be a little bit vertically offset. This is due to the font metrics and how CoreGraphics handles drawing text.
  --ribbon-position <ribbon-position>
                          The position of ribbon. Possible values are : topLeft, topRight, bottomRight or bottomLeft (default: bottomRight)
  --ribbon-color <ribbon-color>
                          The color of the ribbon to use. Possible values are : blue, cyan, gold, green, purple or red (default: cyan)
  --resources-root-path <resources-root-path>
                          Default path of the script root folder. It is not necessary to set when the script is executed as a build phase in Xcode 
  --info-plist <info-plist>
                          Path of the "Info.plist" file of the current target. It is not necessary to set when the script is executed as a build phase in Xcode 
  -v, --verbose           Show extra logging for debugging purposes 
  -i, --input-icon <input-icon>
                          The path of the original icon to use in order to create the badged icon 
  -o, --output-icon <output-icon>
                          The path where the badged icon will be created 
  -h, --help              Show help information.
```

### Target subcommand

```bash
$ iconBadger help target

OVERVIEW: Badge the AppIcon of the current target according to the given options when used from Xcode script build phase.

USAGE: icon-badger target <options>

OPTIONS:
  -t, --text <text>       The text to show on the badge. Possible values are : alpha, beta, version, build, versionAndBuild 
                          or your own custom text. If you choose alpha, beta, version, build or versionAndBuild make sure the script is executed as a build phase in Xcode
  --text-color <text-color>
                          The text color in hex e.g "#000000FF" plus alpha (two last copmponents) (default: "#FFFFFFFF")
  --text-font-name <text-font-name>
                          The font to use for the text. This must be picked from the "Font Book.app" under "PostScript name" (default: MarkerFelt-Thin)
  --text-as-mask          The text is going to be a mask cut off the ribbon to let show the icon background color 
  --text-vertical-bias <x>
                          An optional value between -1.0 and 1.0 to fix an eventual vertical offset of the text. A value of 1.0 matches the ribbon height (default: 0.0)
                          Depending on the choosen font the text might be a little bit vertically offset. This is due to the font metrics and how CoreGraphics handles drawing text.
  --ribbon-position <ribbon-position>
                          The position of ribbon. Possible values are : topLeft, topRight, bottomRight or bottomLeft (default: bottomRight)
  --ribbon-color <ribbon-color>
                          The color of the ribbon to use. Possible values are : blue, cyan, gold, green, purple or red (default: cyan)
  --resources-root-path <resources-root-path>
                          Default path of the script root folder. It is not necessary to set when the script is executed as a build phase in Xcode 
  --info-plist <info-plist>
                          Path of the "Info.plist" file of the current target. It is not necessary to set when the script is executed as a build phase in Xcode 
  -v, --verbose           Show extra logging for debugging purposes 
  --app-icon <app-icon>   The name of the AppIcon in the asset catalog which belongs to the current target (default: AppIcon)
  --app-icon-original <app-icon-original>
                          The name of the Original AppIcon (backup icon) in the asset catalog which belongs to the current target (default: AppIconOriginal)
  --assets-catalog <assets-catalog>
                          The path of the Assets Catalog containing the AppIcon for the current target. If not specified the script will look for the first Assets Catalog in the project path which contains the specified
                          AppIcon. This option is useful for example when you have multiple targets in your project and each target has its AppIcon in a seperate Assets Catalogs but named the same way. 
  --restore-original      Use this flag to restore the original AppIcon, for instance for production build 
  -h, --help              Show help information.
```

## [Author](#author)

Achref Marzouki [https://github.com/ach-ref](https://github.com/ach-ref)

## [License](#license)

`IconBadger` is available under the MIT license. See the LICENSE file for more info.
