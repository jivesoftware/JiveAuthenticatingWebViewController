//
//  JAWVCAuthenticatingWebViewController.m
//  Pods
//
//  Created by Heath Borders on 8/17/15.
//
//

#import "JAWVCAuthenticatingWebViewController.h"
#import <JiveAuthenticatingHTTPProtocol/JAHPAuthenticatingHTTPProtocol.h>

typedef NS_ENUM(NSInteger, JAWVCAuthenticatingWebViewControllerState) {
    JAWVCAuthenticatingWebViewControllerStateNotLoaded = 0,
    JAWVCAuthenticatingWebViewControllerStateNeedsJAHPAuthenticatingHTTPProtocol = 1,
    JAWVCAuthenticatingWebViewControllerStateCanLoadURL = 2,
    JAWVCAuthenticatingWebViewControllerStateAuthenticating = 3,
};

NSString *stringFromJAWVCAuthenticatingWebViewControllerState(JAWVCAuthenticatingWebViewControllerState state) {
    switch (state) {
        case JAWVCAuthenticatingWebViewControllerStateNotLoaded:
            return @"NotLoaded";
        case JAWVCAuthenticatingWebViewControllerStateNeedsJAHPAuthenticatingHTTPProtocol:
            return @"NeedsJAHPAuthenticatingHTTPProtocol";
        case JAWVCAuthenticatingWebViewControllerStateCanLoadURL:
            return @"CanLoadURL";
        case JAWVCAuthenticatingWebViewControllerStateAuthenticating:
            return @"Authenticating";
    }
}

@interface JAWVCAuthenticatingWebViewController () <UIWebViewDelegate, JAHPAuthenticatingHTTPProtocolDelegate>

@property (nonatomic) UIWebView *webView;
@property (nonatomic) JAWVCAuthenticatingWebViewControllerState state;
@property (nonatomic) JAHPAuthenticatingHTTPProtocol *authenticatingHTTPProtocol;

@end

@implementation JAWVCAuthenticatingWebViewController

- (void)dealloc {
    switch (_state) {
        case JAWVCAuthenticatingWebViewControllerStateNotLoaded:
            break;
        case JAWVCAuthenticatingWebViewControllerStateNeedsJAHPAuthenticatingHTTPProtocol:
            break;
        case JAWVCAuthenticatingWebViewControllerStateCanLoadURL:
            [self switchFromCanLoadURLToNeedsJAHPAuthenticatingHTTPProtocol];
            break;
        case JAWVCAuthenticatingWebViewControllerStateAuthenticating:
            [self switchFromAuthenticatingToNeedsJAHPAuthenticatingHTTPProtocol];
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateNotLoaded:
            self.state = JAWVCAuthenticatingWebViewControllerStateNeedsJAHPAuthenticatingHTTPProtocol;
            
            self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
            self.webView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth |
            UIViewAutoresizingFlexibleHeight;
            [self.view addSubview:self.webView];
            
            break;
        default:
            NSLog(@"Illegal state: %@",
                  stringFromJAWVCAuthenticatingWebViewControllerState(self.state));
            abort();
    }
}

#pragma mark - Public API

- (void)loadRequest:(nonnull NSURLRequest *)URLRequest {
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateNeedsJAHPAuthenticatingHTTPProtocol:
            self.state = JAWVCAuthenticatingWebViewControllerStateCanLoadURL;
            
            self.webView.delegate = self;
            [JAHPAuthenticatingHTTPProtocol setDelegate:self];
            [JAHPAuthenticatingHTTPProtocol start];
            
            // fallthrough
        case JAWVCAuthenticatingWebViewControllerStateCanLoadURL:
            [self.webView loadRequest:URLRequest];
            break;
            
        default:
            NSLog(@"Illegal state: %@",
                  stringFromJAWVCAuthenticatingWebViewControllerState(self.state));
            abort();
    }
}

- (void)stop {
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateNeedsJAHPAuthenticatingHTTPProtocol:
            // already done. Nothing to do
            break;
        case JAWVCAuthenticatingWebViewControllerStateCanLoadURL:
            [self switchFromCanLoadURLToNeedsJAHPAuthenticatingHTTPProtocol];
            break;
        default:
            NSLog(@"Illegal state: %@",
                  stringFromJAWVCAuthenticatingWebViewControllerState(self.state));
            abort();
    }
}

- (void)resolvePendingAuthenticationChallengeWithCredential:(nonnull NSURLCredential *)credential {
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateAuthenticating:
            [self switchFromAuthenticatingToCanLoadURLByResolvingWithCredential:credential];
            break;
            
        default:
            break;
    }
}

- (void)cancelPendingAuthenticationChallenge {
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateAuthenticating:
            [self switchFromAuthenticatingToCanLoadURLByCancelling];
            break;
            
        default:
            NSLog(@"Illegal state: %@",
                  stringFromJAWVCAuthenticatingWebViewControllerState(self.state));
            abort();
    }
}

- (NSURLRequest *)URLRequest {
    return self.webView.request;
}

#pragma mark - Private API

- (void)switchFromCanLoadURLToNeedsJAHPAuthenticatingHTTPProtocol {
    self.webView.delegate = nil;
    [JAHPAuthenticatingHTTPProtocol setDelegate:nil];
    [self.webView stopLoading];
    [JAHPAuthenticatingHTTPProtocol stop];
    
    self.state = JAWVCAuthenticatingWebViewControllerStateNeedsJAHPAuthenticatingHTTPProtocol;
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
}

- (void)switchFromAuthenticatingToNeedsJAHPAuthenticatingHTTPProtocol {
    [self switchFromAuthenticatingToCanLoadURLByCancelling];
    [self switchFromCanLoadURLToNeedsJAHPAuthenticatingHTTPProtocol];
}

- (void)switchFromAuthenticatingToCanLoadURLByCancelling {
    self.state = JAWVCAuthenticatingWebViewControllerStateCanLoadURL;
    __typeof(self.authenticatingHTTPProtocol) authenticatingHTTPProtocol = self.authenticatingHTTPProtocol;
    self.authenticatingHTTPProtocol = nil;
    [authenticatingHTTPProtocol cancelPendingAuthenticationChallenge];
}

- (void)switchFromAuthenticatingToCanLoadURLByResolvingWithCredential:(nonnull NSURLCredential *)credential {
    self.state = JAWVCAuthenticatingWebViewControllerStateCanLoadURL;
    __typeof(self.authenticatingHTTPProtocol) authenticatingHTTPProtocol = self.authenticatingHTTPProtocol;
    self.authenticatingHTTPProtocol = nil;
    [authenticatingHTTPProtocol resolvePendingAuthenticationChallengeWithCredential:credential];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateCanLoadURL: {
            __typeof(_delegate) __strong strongDelegate = self.delegate;
            if (strongDelegate) {
                if ([strongDelegate respondsToSelector:@selector(jawvc_authenticatingWebViewController:shouldStartLoadWithRequest:navigationType:)]) {
                    return [self.delegate jawvc_authenticatingWebViewController:self
                                                     shouldStartLoadWithRequest:request
                                                                 navigationType:navigationType];
                } else {
                    return YES;
                }
            } else {
                NSLog(@"Attempted to load %@ without a delegate set. "
                      @"Rejecting the load because any authentication challenges will cause the request to hang.",
                      request);
                return NO;
            }
        }
        default:
            NSLog(@"Illegal state: %@",
                  stringFromJAWVCAuthenticatingWebViewControllerState(self.state));
            abort();
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateCanLoadURL: {
            __typeof(_delegate) __strong strongDelegate = self.delegate;
            if ([strongDelegate respondsToSelector:@selector(jawvc_authenticatingWebViewControllerDidStartLoad:)]) {
                [self.delegate jawvc_authenticatingWebViewControllerDidStartLoad:self];
            }
            break;
        }
        default:
            NSLog(@"Illegal state: %@",
                  stringFromJAWVCAuthenticatingWebViewControllerState(self.state));
            abort();
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateCanLoadURL:
            // fallthrough
        case JAWVCAuthenticatingWebViewControllerStateAuthenticating: {
            __typeof(_delegate) __strong strongDelegate = self.delegate;
            if ([strongDelegate respondsToSelector:@selector(jawvc_authenticatingWebViewControllerDidFinishLoad:)]) {
                [self.delegate jawvc_authenticatingWebViewControllerDidFinishLoad:self];
            }
            break;
        }
        default:
            NSLog(@"Illegal state: %@",
                  stringFromJAWVCAuthenticatingWebViewControllerState(self.state));
            abort();
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateCanLoadURL:
            // fallthrough
        case JAWVCAuthenticatingWebViewControllerStateAuthenticating: {
            __typeof(_delegate) __strong strongDelegate = self.delegate;
            if ([strongDelegate respondsToSelector:@selector(jawvc_authenticatingWebViewController:didFailLoadWithError:)]) {
                [self.delegate jawvc_authenticatingWebViewController:self
                                                didFailLoadWithError:error];
            }
            break;
        }
        default:
            NSLog(@"Illegal state: %@",
                  stringFromJAWVCAuthenticatingWebViewControllerState(self.state));
            abort();
    }
}

#pragma mark - JAHPAuthenticatingHTTPProtocolDelegate

- (BOOL)authenticatingHTTPProtocol:(nonnull JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol
canAuthenticateAgainstProtectionSpace:(nonnull NSURLProtectionSpace *)protectionSpace {
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateCanLoadURL: {
            return [self.delegate jawvc_authenticatingWebViewController:self
                                  canAuthenticateAgainstProtectionSpace:protectionSpace];
        }
        default:
            NSLog(@"Illegal state: %@",
                  stringFromJAWVCAuthenticatingWebViewControllerState(self.state));
            abort();
    }
}

- (nullable JAHPDidCancelAuthenticationChallengeHandler)authenticatingHTTPProtocol:(nonnull JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol
                                                 didReceiveAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge {
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateCanLoadURL: {
            self.authenticatingHTTPProtocol = authenticatingHTTPProtocol;
            self.state = JAWVCAuthenticatingWebViewControllerStateAuthenticating;
            JAWVCDidCancelAuthenticationChallengeHandler didCancelAuthenticationChallengeHandler = [self.delegate jawvc_authenticatingWebViewController:self
                                                                                                                      didReceiveAuthenticationChallenge:challenge];
            if (didCancelAuthenticationChallengeHandler) {
                __typeof(self) __weak weakSelf = self;
                return ^(JAHPAuthenticatingHTTPProtocol *authenticatingHTTPProtocol,
                         NSURLAuthenticationChallenge *challenge) {
                    __typeof(weakSelf) __strong strongWeakSelf = weakSelf;
                    if (strongWeakSelf) {
                        didCancelAuthenticationChallengeHandler(strongWeakSelf,
                                                                challenge);
                    }
                };
            } else {
                return nil;
            }
        }
        default:
            NSLog(@"Illegal state: %@",
                  stringFromJAWVCAuthenticatingWebViewControllerState(self.state));
            abort();
    }
}

- (void)authenticatingHTTPProtocol:(nonnull JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol didCancelAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge {
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateAuthenticating: {
            self.authenticatingHTTPProtocol = nil;
            self.state = JAWVCAuthenticatingWebViewControllerStateCanLoadURL;
            __typeof(_delegate) __strong strongDelegate = self.delegate;
            if ([strongDelegate respondsToSelector:@selector(jawvc_authenticatingWebViewController:didCancelAuthenticationChallenge:)]) {
                [self.delegate jawvc_authenticatingWebViewController:self
                                    didCancelAuthenticationChallenge:challenge];
            }
            break;
        }
        default:
            NSLog(@"Illegal state: %@",
                  stringFromJAWVCAuthenticatingWebViewControllerState(self.state));
            abort();
    }
}

- (void)authenticatingHTTPProtocol:(nullable JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol
                     logWithFormat:(nonnull NSString *)format
                         arguments:(va_list)arguments {
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateCanLoadURL:
            // fallthrough
        case JAWVCAuthenticatingWebViewControllerStateAuthenticating: {
            __typeof(_delegate) __strong strongDelegate = self.delegate;
            if ([strongDelegate respondsToSelector:@selector(jawvc_authenticatingWebViewController:logWithFormat:arguments:)]) {
                [self.delegate jawvc_authenticatingWebViewController:self
                                                       logWithFormat:format
                                                           arguments:arguments];
            }
            break;
        }
        default:
            NSLog(@"Illegal state: %@",
                  stringFromJAWVCAuthenticatingWebViewControllerState(self.state));
            abort();
    }
}

- (void)authenticatingHTTPProtocol:(nullable JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol
                        logMessage:(nonnull NSString *)message {
    switch (self.state) {
        case JAWVCAuthenticatingWebViewControllerStateCanLoadURL:
            // fallthrough
        case JAWVCAuthenticatingWebViewControllerStateAuthenticating: {
            __typeof(_delegate) __strong strongDelegate = self.delegate;
            if ([strongDelegate respondsToSelector:@selector(jawvc_authenticatingWebViewController:logMessage:)]) {
                [self.delegate jawvc_authenticatingWebViewController:self
                                                          logMessage:message];
            }
            break;
        }
        default:
            NSLog(@"Illegal state: %@",
                  stringFromJAWVCAuthenticatingWebViewControllerState(self.state));
            abort();
    }
}

@end
