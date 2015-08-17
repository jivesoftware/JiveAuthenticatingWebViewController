//
//  JAWVCWebViewController.h
//  Pods
//
//  Created by Heath Borders on 8/17/15.
//
//

#import <UIKit/UIKit.h>

@protocol JAWVCAuthenticatingWebViewControllerDelegate;

/*! Present a JAWVCWebViewController to support NSURLAuthenticationChallenges with a UIWebView.
 *  Due to limitations of NSURLProtocol, only one instance of this class should be used at a time.
 */
@interface JAWVCAuthenticatingWebViewController : UIViewController

@property (nonatomic, weak) id<JAWVCAuthenticatingWebViewControllerDelegate> __nullable delegate;
@property (nonatomic, readonly) NSURLRequest * __nullable URLRequest;

/*! See -[UIWebView loadRequest:]
 */
- (void)loadRequest:(nonnull NSURLRequest *)URLRequest;

/*! This class disables its NSURLProtocol on -dealloc. If you need to disable the protocol sooner (probably because you need to use another UIWebView while this one is still present in the view controller hierarchy), call this method. This method also stops any active UIWebView loads and switches the UIWebView to about:blank.
 */
- (void)stop;

/*! Resolves the NSURLAuthenticationChallenge provided by -[JAWVCAuthenticatingWebViewControllerDelegate jawvc_authenticatingWebViewController:canAuthenticateAgainstProtectionSpace:]. Do not use the NSURLAuthenticationChallenge methods directly.
 */
- (void)resolvePendingAuthenticationChallengeWithCredential:(nonnull NSURLCredential *)credential;

/*! Cancels the NSURLAuthenticationChallenge provided by -[JAWVCAuthenticatingWebViewControllerDelegate jawvc_authenticatingWebViewController:canAuthenticateAgainstProtectionSpace:]. Do not use the NSURLAuthenticationChallenge methods directly.
 */
- (void)cancelPendingAuthenticationChallenge;

@end

typedef void (^JAWVCDidCancelAuthenticationChallengeHandler)(
                                                             JAWVCAuthenticatingWebViewController * __nonnull authenticatingWebViewController,
                                                             NSURLAuthenticationChallenge * __nonnull challenge);

@protocol JAWVCAuthenticatingWebViewControllerDelegate <NSObject>

/*! See -[JAHPAuthenticatingHTTPProtocolDelegate authenticatingHTTPProtocol:canAuthenticateAgainstProtectionSpace:]
 */
- (BOOL)jawvc_authenticatingWebViewController:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController
        canAuthenticateAgainstProtectionSpace:(nonnull NSURLProtectionSpace *)protectionSpace;

/*! See -[JAHPAuthenticatingHTTPProtocolDelegate authenticatingHTTPProtocol:didReceiveAuthenticationChallenge:]
 */
- (nullable JAWVCDidCancelAuthenticationChallengeHandler)jawvc_authenticatingWebViewController:(nonnull JAWVCAuthenticatingWebViewController *)webViewController
                                                             didReceiveAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge;

@optional

/*! See -[UIWebViewDelegate webView:shouldStartLoadWithRequest:navigationType:]
 */
- (BOOL)jawvc_authenticatingWebViewController:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController
                   shouldStartLoadWithRequest:(nonnull NSURLRequest *)URLRequest
                               navigationType:(UIWebViewNavigationType)navigationType;

/*! See -[UIWebViewDelegate webViewDidStartLoad:]
 */
- (void)jawvc_authenticatingWebViewControllerDidStartLoad:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController;

/*! See -[UIWebViewDelegate webViewDidFinishLoad:]
 */
- (void)jawvc_authenticatingWebViewControllerDidFinishLoad:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController;

/*! See -[UIWebViewDelegate webView:didFailLoadWithError:]
 */
- (void)jawvc_authenticatingWebViewController:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController
                         didFailLoadWithError:(nonnull NSError *)error;

/*! See -[JAHPAuthenticatingHTTPProtocolDelegate authenticatingHTTPProtocol:didCancelAuthenticationChallenge:]
 */
- (void)jawvc_authenticatingWebViewController:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController
             didCancelAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge;

/*! See -[JAHPAuthenticatingHTTPProtocolDelegate authenticatingHTTPProtocol:logWithFormat:arguments:]
 */
- (void)jawvc_authenticatingWebViewController:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController
                                logWithFormat:(nonnull NSString *)format
// clang's static analyzer doesn't know that a va_list can't have an nullability annotation.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"
                                    arguments:(va_list)arguments;
#pragma clang diagnostic pop

/*! See -[JAHPAuthenticatingHTTPProtocolDelegate authenticatingHTTPProtocol:logMessage:]
 */
- (void)jawvc_authenticatingWebViewController:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController
                                   logMessage:(nonnull NSString *)message;

@end
