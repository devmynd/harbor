source 'https://github.com/CocoaPods/Specs.git'

# platform
platform :osx, '10.11'
use_frameworks!

# build configuration inheritance
project 'Harbor', 'Test' => :debug

# dependencies
target 'Harbor' do
  pod 'Alamofire', '~> 4.0'
  pod 'AlamofireObjectMapper', '~> 4.0'

  target 'HarborTests' do
    pod 'Quick', '~> 1.0'
    pod 'Nimble', '~> 5.0'
  end
end

