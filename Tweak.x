#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ─── جلب معلومات التطبيق ───────────────────────────────────────────
static NSString *GetAppInfo(void) {
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = bundle.infoDictionary;

    NSString *appName    = info[@"CFBundleDisplayName"]
                        ?: info[@"CFBundleName"]
                        ?: @"Unknown";
    NSString *bundleID   = bundle.bundleIdentifier ?: @"Unknown";
    NSString *version    = info[@"CFBundleShortVersionString"] ?: @"?";
    NSString *build      = info[@"CFBundleVersion"] ?: @"?";
    NSString *minOS      = info[@"MinimumOSVersion"] ?: @"?";

    UIDevice *device     = UIDevice.currentDevice;
    NSString *deviceName = device.name;
    NSString *sysVersion = device.systemVersion;
    NSString *model      = device.model;

    return [NSString stringWithFormat:
        @"📱 App Name   : %@\n"
         "🔑 Bundle ID  : %@\n"
         "🏷  Version   : %@ (%@)\n"
         "🔧 Min iOS    : %@\n"
         "────────────────────\n"
         "📟 Device     : %@ (%@)\n"
         "🍎 iOS        : %@",
        appName, bundleID, version, build, minOS,
        deviceName, model, sysVersion];
}

// ─── عرض التنبيه ──────────────────────────────────────────────────
static BOOL gAlertVisible = NO;

static void ShowAppInfo(UIViewController *presenter) {
    if (gAlertVisible) return;

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"ℹ️ App Info"
                                            message:GetAppInfo()
                                     preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *closeAction =
        [UIAlertAction actionWithTitle:@"Close"
                                 style:UIAlertActionStyleCancel
                               handler:^(UIAlertAction *a) {
                                   gAlertVisible = NO;
                               }];

    [alert addAction:closeAction];

    // تنسيق النص بخط ثابت (monospaced) لعرض أجمل
    NSMutableAttributedString *msg =
        [[NSMutableAttributedString alloc]
            initWithString:GetAppInfo()
                attributes:@{
                    NSFontAttributeName:
                        [UIFont fontWithName:@"Menlo" size:12]
                        ?: [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular],
                    NSForegroundColorAttributeName:
                        [UIColor labelColor]
                }];

    [alert setValue:msg forKey:@"attributedMessage"];

    gAlertVisible = YES;
    [presenter presentViewController:alert animated:YES completion:nil];
}

// ─── إيجاد أعلى ViewController ────────────────────────────────────
static UIViewController *TopViewController(void) {
    UIWindow *window = nil;

    if (@available(iOS 15.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;
                for (UIWindow *w in ws.windows) {
                    if (w.isKeyWindow) { window = w; break; }
                }
                if (window) break;
            }
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        window = UIApplication.sharedApplication.keyWindow;
#pragma clang diagnostic pop
    }

    UIViewController *vc = window.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

// ─── Hook: التقاط اللمس من أي مكان ───────────────────────────────
%hook UIWindow

- (void)sendEvent:(UIEvent *)event {
    %orig;

    if (event.type == UIEventTypeTouches) {
        UITouch *touch = event.allTouches.anyObject;
        if (touch && touch.phase == UITouchPhaseBegan) {
            // عدد اللمسات: 3 أصابع في نفس الوقت لتفادي التفعيل العرضي
            // غيّر الشرط لـ  == 1  لو تريد لمسة واحدة تكفي
            if (event.allTouches.count == 3) {
                UIViewController *top = TopViewController();
                if (top) ShowAppInfo(top);
            }
        }
    }
}

%end
