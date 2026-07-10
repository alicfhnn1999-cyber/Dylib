#import <UIKit/UIKit.h>

// ─── متغير لمنع تكرار التنبيه ──────────────────────────────────────
static BOOL gAlertVisible = NO;

// ─── جلب معلومات التطبيق ───────────────────────────────────────────
static NSString *GetAppInfo(void) {
    @try {
        NSBundle *bundle = [NSBundle mainBundle];
        NSDictionary *info = bundle.infoDictionary;

        NSString *appName  = info[@"CFBundleDisplayName"]
                          ?: info[@"CFBundleName"]
                          ?: @"Unknown";
        NSString *bundleID = bundle.bundleIdentifier ?: @"Unknown";
        NSString *version  = info[@"CFBundleShortVersionString"] ?: @"?";
        NSString *build    = info[@"CFBundleVersion"] ?: @"?";
        NSString *minOS    = info[@"MinimumOSVersion"] ?: @"?";

        UIDevice *device      = UIDevice.currentDevice;
        NSString *deviceName  = device.name ?: @"?";
        NSString *sysVersion  = device.systemVersion ?: @"?";
        NSString *model       = device.model ?: @"?";

        return [NSString stringWithFormat:
            @"App Name : %@\n"
             "Bundle ID: %@\n"
             "Version  : %@ (%@)\n"
             "Min iOS  : %@\n"
             "-------------------\n"
             "Device   : %@ (%@)\n"
             "iOS      : %@",
            appName, bundleID, version, build,
            minOS, deviceName, model, sysVersion];
    } @catch (NSException *e) {
        return @"Could not read app info.";
    }
}

// ─── إيجاد أعلى ViewController بأمان ─────────────────────────────
static UIViewController *TopViewController(void) {
    @try {
        UIWindow *keyWindow = nil;

        if (@available(iOS 13.0, *)) {
            NSSet<UIScene *> *scenes = UIApplication.sharedApplication.connectedScenes;
            for (UIScene *scene in scenes) {
                if (![scene isKindOfClass:[UIWindowScene class]]) continue;
                UIWindowScene *ws = (UIWindowScene *)scene;
                for (UIWindow *w in ws.windows) {
                    if (w.isKeyWindow) { keyWindow = w; break; }
                }
                if (keyWindow) break;
            }
        }

        // fallback لـ iOS 12 وما دون
        if (!keyWindow) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            keyWindow = UIApplication.sharedApplication.keyWindow;
#pragma clang diagnostic pop
        }

        if (!keyWindow) return nil;

        UIViewController *vc = keyWindow.rootViewController;
        if (!vc) return nil;

        // الصعود لأعلى VC معروض
        while (vc.presentedViewController) {
            vc = vc.presentedViewController;
        }
        return vc;
    } @catch (NSException *e) {
        return nil;
    }
}

// ─── عرض التنبيه على Main Thread فقط ─────────────────────────────
static void ShowAppInfo(void) {
    if (gAlertVisible) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            UIViewController *top = TopViewController();
            if (!top) return;

            // منع العرض إذا كان VC غير جاهز
            if (!top.isViewLoaded || !top.view.window) return;

            gAlertVisible = YES;

            UIAlertController *alert =
                [UIAlertController
                    alertControllerWithTitle:@"App Info"
                                     message:GetAppInfo()
                              preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *close =
                [UIAlertAction actionWithTitle:@"Close"
                                         style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *a) {
                                           gAlertVisible = NO;
                                       }];
            [alert addAction:close];

            [top presentViewController:alert animated:YES completion:nil];

        } @catch (NSException *e) {
            gAlertVisible = NO;
            NSLog(@"[AppInfoTweak] Error showing alert: %@", e);
        }
    });
}

// ─── Hook: اعتراض اللمس ───────────────────────────────────────────
%hook UIWindow

- (void)sendEvent:(UIEvent *)event {
    %orig; // استدعاء الأصلي أولاً دائماً

    @try {
        // تأكد من نوع الحدث
        if (event.type != UIEventTypeTouches) return;

        NSSet<UITouch *> *touches = [event allTouches];
        if (!touches || touches.count == 0) return;

        UITouch *touch = [touches anyObject];
        if (!touch) return;

        // فقط عند بدء اللمس وبـ 3 أصابع
        if (touch.phase == UITouchPhaseBegan && touches.count == 3) {
            ShowAppInfo();
        }
    } @catch (NSException *e) {
        // لا نسمح لأي exception يكسر sendEvent
        NSLog(@"[AppInfoTweak] sendEvent exception: %@", e);
    }
}

%end
