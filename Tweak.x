#import <UIKit/UIKit.h>

static void ShowWelcomeMessage(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

        UIWindow *window = nil;

        if (@available(iOS 15.0, *)) {
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    window = windowScene.windows.firstObject;
                    if (window) break;
                }
            }
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            window = UIApplication.sharedApplication.windows.firstObject;
#pragma clang diagnostic pop
        }

        if (!window || !window.rootViewController) return;

        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"👋 Welcome"
                                            message:@"Welcome to this app!"
                                     preferredStyle:UIAlertControllerStyleAlert];

        [window.rootViewController presentViewController:alert
                                                animated:YES
                                              completion:nil];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

%hook UIApplication

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    ShowWelcomeMessage();
}

%end
