//
//  Photo.h
//  PhotoRetriever
//
//  Created by Dianna Mertz on 10/19/14.
//  Copyright (c) 2014 Dianna Mertz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Photo : NSObject

@property (nonatomic, strong) NSString *photographerName;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *imageURLString;
@property (nonatomic, strong) UIImage *photographerImage;
@property (nonatomic, strong) NSString *photographerImageURLString;

@end
