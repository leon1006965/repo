#import "OverlapShared.h"

@interface SBHIconManager : NSObject
- (id)currentTransitionAnimator;
- (void)setCurrentTransitionAnimator:(id)arg1;
@end

@interface SBHomeScreenIconTransitionAnimator : NSObject
- (id)iconAnimator;
- (void)cancel;
- (void)cancelTransition:(id)arg1 withCompletionSpeed:(double)arg2 completionCurve:(long long)arg3;
- (void)animationEnded:(BOOL)arg1;
- (unsigned long long)operation;
@end

static void OVLog(NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    NSLog(@"[Overlap] %@", msg);
}

%hook SBHIconManager

- (void)setCurrentTransitionAnimator:(id)arg1 {
    id old = [self currentTransitionAnimator];
    %orig;
    if (arg1 && old && arg1 != old) {
        OVLog(@"transition replaced: %@ -> %@", old, arg1);
        OVMarkInterrupted(old);
        id inner = [old valueForKey:@"iconAnimator"];
        if (inner) OVMarkInterrupted(inner);
    }
}

%end

%hook SBHomeScreenIconTransitionAnimator

- (void)cancel {
    if (OVIsInterrupted(self)) {
        OVLog(@"cancel blocked (op=%lu): %@", (unsigned long)[self operation], self);
        return;
    }
    %orig;
}

- (void)cancelTransition:(id)arg1 withCompletionSpeed:(double)arg2 completionCurve:(long long)arg3 {
    if (OVIsInterrupted(self)) {
        OVLog(@"cancelTransition blocked (op=%lu): %@", (unsigned long)[self operation], self);
        return;
    }
    %orig;
}

- (void)animationEnded:(BOOL)arg1 {
    if (OVIsInterrupted(self)) {
        OVLog(@"transition ended (cancelled=%d, op=%lu)", arg1, (unsigned long)[self operation]);
        OVClearInterrupted(self);
        id inner = [self iconAnimator];
        if (inner) OVClearInterrupted(inner);
    }
    %orig;
}

%end
