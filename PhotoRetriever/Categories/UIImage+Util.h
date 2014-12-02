//
//  UIImage+Util.h
//  PhotoRetriever
//
//  Created by Dianna Mertz on 10/19/14.
//  Copyright (c) 2014 Dianna Mertz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Util)

+ (UIImage *)cropToSquare:(UIImage *)image scaledToFillSize:(CGSize)size;

@end
