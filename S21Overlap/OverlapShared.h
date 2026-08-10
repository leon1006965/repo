#ifndef OVERLAP_TWEAK_H
#define OVERLAP_TWEAK_H

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static const void *kOVInterruptedKey = &kOVInterruptedKey;

static BOOL OVIsInterrupted(id obj) {
    if (!obj) return NO;
    return [objc_getAssociatedObject(obj, kOVInterruptedKey) boolValue];
}

static void OVClearInterrupted(id obj) {
    if (!obj) return;
    objc_setAssociatedObject(obj, kOVInterruptedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void OVMarkInterrupted(id obj) {
    if (!obj) return;
    objc_setAssociatedObject(obj, kOVInterruptedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak id weakObj = obj;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        OVClearInterrupted(weakObj);
    });
}

#endif
