Pod::Spec.new do |s|
  s.name = 'JiveAuthenticatingWebViewController'
  s.version = '0.1.0'
  s.license = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.summary = 'A UIViewController containing a UIWebView that uses JiveAuthenticatingHTTPProtocol to respond to NSURLAuthenticationChallenges'
  s.homepage = 'https://github.com/jivesoftware/JiveAuthenticatingWebViewController'
  s.social_media_url = 'http://twitter.com/JiveSoftware'
  s.authors = { 'Jive Mobile' => 'jive-mobile@jivesoftware.com' }
  s.source = { :git => 'https://github.com/jivesoftware/JiveAuthenticatingWebViewController.git', :tag => s.version }

  s.ios.deployment_target = '7.0'

  s.requires_arc = true
  s.source_files = 'Source/JiveAuthenticatingWebViewController/*.{h,m}'
  s.dependency 'JiveAuthenticatingHTTPProtocol', '0.3.2'

end
