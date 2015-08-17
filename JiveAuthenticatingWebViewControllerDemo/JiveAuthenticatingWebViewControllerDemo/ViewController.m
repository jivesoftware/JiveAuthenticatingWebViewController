//
//  ViewController.m
//  JiveAuthenticatingWebViewControllerDemo
//
//  Created by Heath Borders on 8/17/15.
//  Copyright (c) 2015 Heath Borders. All rights reserved.
//

#import "ViewController.h"
#import <JiveAuthenticatingWebViewController/JAWVCAuthenticatingWebViewController.h>

@interface ViewController () <JAWVCAuthenticatingWebViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic) JAWVCAuthenticatingWebViewController *authenticatingWebViewController;
@property (nonatomic) UIAlertView *authAlertView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    startButton.frame = self.view.bounds;
    [startButton setTitle:@"Start"
                 forState:UIControlStateNormal];
    [startButton addTarget:self
                    action:@selector(startButtonTouchUpInside)
          forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:startButton];
}

#pragma mark - JAWVCAuthenticatingWebViewControllerDelegate

- (BOOL)jawvc_authenticatingWebViewController:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController
        canAuthenticateAgainstProtectionSpace:(nonnull NSURLProtectionSpace *)protectionSpace {
    BOOL canAuthenticate = [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic];
    return canAuthenticate;
}

- (nullable JAWVCDidCancelAuthenticationChallengeHandler)jawvc_authenticatingWebViewController:(nonnull JAWVCAuthenticatingWebViewController *)webViewController
                                                             didReceiveAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge {
    self.authAlertView = [[UIAlertView alloc] initWithTitle:@"JAWVCDemo HTTP BASIC Login"
                                                    message:@"Enter 'foo' for the username and 'bar' for the password"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:
                          @"OK",
                          nil];
    self.authAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    // Bug in UIAlertView:
    // if the keyboard is aleady showing, presenting a LoginAndPasswordInput UIAlertView
    // will crash with an InternalInconsistencyException:
    // 'The layout constraints still need update after sending -updateConstraints to <_UIKeyboardLayoutAlignmentView: 0x7f924428a4a0; frame = (0 0; 0 0); userInteractionEnabled = NO; layer = <CALayer: 0x7f92442ae310>>. _UIKeyboardLayoutAlignmentView or one of its superclasses may have overridden -updateConstraints without calling super. Or, something may have dirtied layout constraints in the middle of updating them.  Both are programming errors.'
    // The workaround is to set the UIAlertView's login UITextField to first responder.
    // http://stackoverflow.com/a/30265898/9636
    [[self.authAlertView textFieldAtIndex:0] becomeFirstResponder];
    [self.authAlertView show];
    
    return ^(JAWVCAuthenticatingWebViewController *authenticatingWebViewController, NSURLAuthenticationChallenge *challenge) {
        [self.authAlertView dismissWithClickedButtonIndex:self.authAlertView.cancelButtonIndex
                                                 animated:YES];
        self.authAlertView = nil;
        
        [[[UIAlertView alloc] initWithTitle:@"JAWVCDemo"
                                    message:@"The URL Loading System cancelled authentication"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    };
}

- (BOOL)jawvc_authenticatingWebViewController:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController
                   shouldStartLoadWithRequest:(nonnull NSURLRequest *)URLRequest
                               navigationType:(UIWebViewNavigationType)navigationType {
    // this is the default behavior.
    // I'm only overriding this method to call out its existence on the JAWVCAuthenticatingWebViewControllerDelegate.
    // You might return something other than YES if you don't want to follow redirects or something.
    return YES;
}

- (void)jawvc_authenticatingWebViewControllerDidStartLoad:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController {
    NSLog(@"started: %@",
          authenticatingWebViewController.URLRequest);
}

- (void)jawvc_authenticatingWebViewControllerDidFinishLoad:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController {
    NSLog(@"finished: %@",
          authenticatingWebViewController.URLRequest);
}

- (void)jawvc_authenticatingWebViewController:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController
                         didFailLoadWithError:(nonnull NSError *)error {
    NSLog(@"error: %@ %@",
          [error localizedDescription],
          [error userInfo]);
    [[[UIAlertView alloc] initWithTitle:@"JAWVCDemo Error"
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (void)jawvc_authenticatingWebViewController:(nonnull JAWVCAuthenticatingWebViewController *)authenticatingWebViewController
                                   logMessage:(nonnull NSString *)message {
    NSLog(@"authenticatingWebViewController logMessage: %@",
          message);
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == self.authAlertView.cancelButtonIndex) {
        [self cancelChallengeAfterAlertViewDismissal];
    } else if (buttonIndex == self.authAlertView.firstOtherButtonIndex) {
        [self useAuthAlertViewUsernamePasswordForChallenge];
    }
}

- (void)alertViewCancel:(UIAlertView *)alertView {
    [self cancelChallengeAfterAlertViewDismissal];
}

#pragma mark - IBActions

- (void)startButtonTouchUpInside {
    self.authenticatingWebViewController = [JAWVCAuthenticatingWebViewController new];
    self.authenticatingWebViewController.delegate = self;
    self.authenticatingWebViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.authenticatingWebViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                                                          target:self
                                                                                                                          action:@selector(authenticatingWebViewControllerRefreshBarButtonItemTouchUpInside)];
    self.authenticatingWebViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                                           target:self
                                                                                                                           action:@selector(authenticatingWebViewControllerDoneBarButtonItemTouchUpInside)];
    
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:self.authenticatingWebViewController]
                       animated:YES
                     completion:^{
                         [self.authenticatingWebViewController loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://httpbin.org/basic-auth/foo/bar"]]];
                     }];
}

- (void)authenticatingWebViewControllerRefreshBarButtonItemTouchUpInside {
    [self.authenticatingWebViewController loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://httpbin.org/basic-auth/foo/bar"]]];
}

- (void)authenticatingWebViewControllerDoneBarButtonItemTouchUpInside {
    self.authenticatingWebViewController.delegate = nil;
    self.authenticatingWebViewController = nil;
    [self dismissViewControllerAnimated:YES
                             completion:NULL];
}

#pragma mark - Private API

- (void)cancelChallengeAfterAlertViewDismissal {
    [self.authenticatingWebViewController cancelPendingAuthenticationChallenge];
    self.authAlertView = nil;
}

- (void)useAuthAlertViewUsernamePasswordForChallenge {
    NSString *username = [self.authAlertView textFieldAtIndex:0].text;
    NSString *password = [self.authAlertView textFieldAtIndex:1].text;
    self.authAlertView = nil;
    NSURLCredential *credential = [NSURLCredential credentialWithUser:username
                                                             password:password
                                                          persistence:NSURLCredentialPersistenceNone];
    [self.authenticatingWebViewController resolvePendingAuthenticationChallengeWithCredential:credential];
}

@end
