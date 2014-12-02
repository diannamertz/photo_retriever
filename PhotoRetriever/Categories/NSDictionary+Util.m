//
//  NSDictionary+Util.m
//  PhotoRetriever
//
//  Created by Dianna Mertz on 10/19/14.
//  Copyright (c) 2014 Dianna Mertz. All rights reserved.
//

#import "NSDictionary+Util.h"

@implementation NSDictionary (Util)

-(id)objectForKeyNotNull:(NSString *)key
{
    id object = [self objectForKey:key];
    if((NSNull *)object == [NSNull null] || (__bridge CFNullRef)object == kCFNull)
        return nil;
    
    return object;
}

@end
