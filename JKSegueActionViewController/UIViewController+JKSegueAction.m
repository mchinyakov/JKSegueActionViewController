//
//  UIViewController+JKSegueAction.m
//  JKSegueActionViewController
//
//  Created by Joseph Kain on 5/4/13.
//  Copyright (c) 2013 Joseph Kain.
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//    THE SOFTWARE.

#import "UIViewController+JKSegueAction.h"
#import <objc/message.h>

static char *JKSegueActionMapKey = "JKSegueActionMapKey";


@implementation UIViewController (JKSegueAction)

- (NSMutableDictionary *) map {
    NSMutableDictionary *map = objc_getAssociatedObject(self, &JKSegueActionMapKey);
    if (!map) {
        map = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &JKSegueActionMapKey, map, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return map;
}

- (NSDictionary *) blocksForSegueWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *map = [self map];
    return map[identifier];
}

- (void)restoreBlocks:(NSDictionary *)savedBlocksDictionary forSegueWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *map = [self map];
    
    if (savedBlocksDictionary) {
        map[identifier] = savedBlocksDictionary;
    } else {
        [map removeObjectForKey:identifier];
    }
}

- (BOOL)hasBlocksForSegue:(UIStoryboardSegue *)segue {
    return ([self blocksForSegueWithIdentifier:segue.identifier] != nil);
}

- (void)performBlockForSegue:(UIStoryboardSegue *)segue withSender:(id)sender {
    NSDictionary *blocks = [self blocksForSegueWithIdentifier:segue.identifier];
    
    NSArray * keys = [[blocks allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for (NSString * key in keys) {
        JKSegueActionBlock block = blocks[key];
        if (! block)
            continue;
        block(segue, sender);
    }
}

-(void)invokeSelectorForSegue:(UIStoryboardSegue *)segue withSender:(id)sender {
    SEL selector = NSSelectorFromString(segue.identifier);
    
    if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector withObject:segue withObject:sender];
#pragma clang diagnostic pop
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([self hasBlocksForSegue:segue]) {
        [self performBlockForSegue:segue withSender:sender];
    } else {
        [self invokeSelectorForSegue:segue withSender:sender];
    }
}
#pragma clang diagnostic pop

- (void) clearActionsForSegueWithIdentifier:(NSString *)identifier{
    NSMutableDictionary *map = [self map];
    [map removeObjectForKey:identifier];
}

- (void) addActionForSegueWithIdentifier:(NSString *)identifier toBlock:(JKSegueActionBlock) block andBlockName:(NSString *) blockName {
    
    NSMutableDictionary *map = [self map];
    if (map[identifier] == nil) {
        map[identifier] = [NSMutableDictionary new];
    }
    if (blockName == nil) {
        blockName = [@((NSUInteger)[[map[identifier] allKeys] count] + 1) stringValue];
    }
    
    NSMutableDictionary * blocks = (NSMutableDictionary *)map[identifier];
    [blocks setObject:block forKey:blockName ];
}

- (void) setActionForSegueWithIdentifier:(NSString *)identifier toBlock:(JKSegueActionBlock) block {
    [self clearActionsForSegueWithIdentifier:identifier];
    [self addActionForSegueWithIdentifier:identifier toBlock:block andBlockName:nil];
}

- (void) performSegueWithIdentifier:(NSString *)identifier sender:(id)sender withBlock:(JKSegueActionBlock) block
{
    NSDictionary *savedBlocks = [self blocksForSegueWithIdentifier:identifier];
    
    // This isn't threadsafe but then again UIKit should only be used from the main thread so this is OK?
    [self clearActionsForSegueWithIdentifier:identifier];
    [self setActionForSegueWithIdentifier:identifier toBlock:block];
    [self performSegueWithIdentifier:identifier sender:sender];
    [self restoreBlocks:savedBlocks forSegueWithIdentifier:identifier];
}
@end
