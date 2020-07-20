Pod::Spec.new do |s|
    s.source_files = '*.swift'
    s.name = 'MockAPI'
    s.authors = 'Hiroya Hinomori'
    s.summary = 'API for Mock'
    s.version = '0.0.1'
    s.homepage = 'https://github.com/aquiz-all/tokutown-api-ios'
    s.source = { :git => 'https://github.com/aquiz-all/tokutown-api-ios.git' }
    s.ios.deployment_target = '13.0'
    s.source_files = 'Sources/**/*.swift'
    s.dependency 'Moya/Moya', '~> 14.0.0'
end
