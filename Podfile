platform :osx, '10.10'
use_frameworks!

def testing_pods
    pod 'Quick', '~> 0.6.0'
    pod 'Nimble', '2.0.0-rc.3'
end

target 'Harbor' do
    pod 'Alamofire', '~> 3.0'
end

target 'HarborTests' do
    testing_pods
end

target 'HarborUITests' do
    testing_pods
end
