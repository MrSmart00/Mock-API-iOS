Pod::Spec.new do |s|
    s.source_files = '*.swift'
    s.name = '{{ options.name }}'
    s.authors = '{{ options.authors|default:"Hiroya Hinomori" }}'
    s.summary = '{{ info.description|default:"A generated API" }}'
    s.version = '{{ info.version }}'
    s.homepage = 'https://github.com/aquiz-all/tokutown-api-ios'
    s.source = { :git => 'https://github.com/aquiz-all/tokutown-api-ios.git' }
    s.ios.deployment_target = '13.0'
    s.source_files = 'Sources/**/*.swift'
    {% for dependency in options.dependencies %}
    s.dependency '{{ dependency.pod }}', '~> {{ dependency.version }}'
    {% endfor %}
end
