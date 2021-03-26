Pod::Spec.new do |spec|
  
  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.name               = 'IconBadger'
  spec.version            = '1.0.0'
  spec.summary            = 'Script adding dynamically a badge with a custom text to the app\'s icon on build time'
  spec.homepage           = 'https://github.com/ach-ref/IconBadger'
  spec.description        = <<-DESC
                            Script written in Swift that prepares the iOS app icon overlay with a ribbon and a given text
                            such as alpha, beta or version and build numbers
                            DESC
  
  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.license            = { :type => 'MIT', :file => 'LICENSE' }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.author             = { 'Achref Marzouki' => 'contact@amarzouki.com' }
  spec.social_media_url   = 'https://amarzouki.com'
  spec.source             = { :git => 'https://github.com/ach-ref/IconBadger.git', :tag => spec.version.to_s }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.platform           = :ios, '9.0'
  spec.swift_version      = '5'


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  
  spec.preserve_paths     = 'resources/**/*'

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  
  spec.requires_arc       = true
  spec.prepare_command    = 'swift build -c release && cp -f .build/x86_64-apple-macosx/release/iconBadger resources/bin/iconBadger'
end
