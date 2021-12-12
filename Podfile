# Uncomment the next line to define a global platform for your project
# platform :ios, '15.0'

target 'Cesium' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  
  # Pods for Cesium
  pod 'Sodium', '~> 0.8.0'
  pod 'CryptoSwift', :git => "https://github.com/krzyzanowskim/CryptoSwift", :branch => "main"
  pod 'Base58String', :git => 'https://github.com/cloutiertyler/Base58String.git'
  pod 'SwipeableTabBarController'
  pod 'SipHash', '~> 1.2'
  pod 'BigInt', :git => 'https://github.com/attaswift/BigInt', :tag => 'v5.3.0'

  target 'CesiumTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'CesiumUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
