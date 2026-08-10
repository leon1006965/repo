#import "OverlapShared.h"

@interface SBHIconManager : NSObject
- (id)currentTransitionAnimator;
- (void)setCurrentTransitionAnimator:(id)arg1;
@end

%hook SBHIconManager

- (void)setCurrentTransitionAnimator:(id)arg1 {
    id old = [self currentTransitionAnimator];
    %orig;
    if (arg1 && old && arg1 != old) {
        OVMarkInterrupted(old);
        id inner = [old valueForKey:@"iconAnimator"];
        if (inner) OVMarkInterrupted(inner);
    }
}

%end

%hook SBIconAnimator

- (void)cleanup {
    if (OVIsInterrupted(self)) {
        return;
    }
    %orig;
}

%end

%hook SBIconZoomAnimator

- (void)cleanupZoom {
    if (OVIsInterrupted(self)) {
        return;
    }
    %orig;
}

%end

%hook SBScaleIconZoomAnimator

- (void)_cleanupAnimation {
    if (OVIsInterrupted(self)) {
        return;
    }
    %orig;
}

%end
