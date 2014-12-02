//
//  ViewController.m
//  PhotoRetriever
//
//  Created by Dianna Mertz on 10/19/14.
//  Copyright (c) 2014 Dianna Mertz. All rights reserved.
//

#import "PhotoTableViewController.h"
#import "Photo.h"
#import "NSDictionary+Util.h"
#import "UIImage+Util.h"

static NSString *const INSTAGRAM_URL = @"https://api.instagram.com/v1/media/popular?client_id=50c0e12b64a84dd0b9bbf334ba7f6bf6";

static NSString *cellIdentifier = @"photoCellId";

@interface PhotoTableViewCell : UITableViewCell
@property (nonatomic, strong) UIImageView *photographerImageView;
@property (nonatomic, strong) UIImageView *photoImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@end

@implementation PhotoTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
}

@end

@interface PhotoTableViewController ()
{
    CGFloat cellHeight;
}

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation PhotoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[PhotoTableViewCell class] forCellReuseIdentifier:cellIdentifier];
    
    self.title = @"Photo Retriever";
    
    cellHeight = self.view.frame.size.width;
    
    self.photoArray = [NSMutableArray array];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self refresh];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Loading Images

- (void)refresh
{
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:INSTAGRAM_URL] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        
        NSData *jsonData = [[NSData alloc] initWithContentsOfURL:location];
        
        NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        
        [self parsePhotoFromResponse:dataDictionary];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
            [self.tableView reloadData];
        });
        
    }];
    
    [task resume];
}

- (void)parsePhotoFromResponse:(NSDictionary *)response
{
    if (response != nil) {
        NSArray *dataArray = [response objectForKeyNotNull:@"data"];
        
        for (NSDictionary *photoDictionary in dataArray) {
            
            NSDictionary *userDictionary = [photoDictionary objectForKeyNotNull:@"user"];
            NSDictionary *imagesDictionary = [photoDictionary objectForKeyNotNull:@"images"];
            NSDictionary *imageDictionary = [imagesDictionary objectForKeyNotNull:@"standard_resolution"];
            
            Photo *photo = [Photo new];
            
            [photo setValue:[userDictionary objectForKeyNotNull:@"username"] forKey:@"photographerName"];
            [photo setValue:[userDictionary objectForKeyNotNull:@"profile_picture"] forKey:@"photographerImageURLString"];
            [photo setValue:[imageDictionary objectForKeyNotNull:@"url"] forKey:@"imageURLString"];
            
            [self.photoArray insertObject:photo atIndex:0];
        }
    }
}

#pragma mark - UITableView
#pragma mark Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // if the photo array is empty, display enough rows to fill view
    return (self.photoArray.count > 0) ? self.photoArray.count : tableView.visibleCells.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return cellHeight + 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell.photographerImageView) {
        cell.photographerImageView = [[UIImageView alloc] init];
        [cell addSubview:cell.photographerImageView];
        cell.photographerImageView.image = [UIImage imageNamed:@"Placeholder"];
    }
    
    if (!cell.photoImageView) {
        cell.photoImageView = [[UIImageView alloc] init];
        [cell addSubview:cell.photoImageView];
        cell.photoImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    if (!cell.nameLabel) {
        cell.nameLabel = [[UILabel alloc] init];
        [cell addSubview:cell.nameLabel];
    }
    
    [self setConstraintsForNameLabel:cell.nameLabel andPhotographerImageView:cell.photographerImageView andPhotoView:cell.photoImageView onCell:cell];
    
    if (self.photoArray.count > 0) {
        
        Photo *photo = [self.photoArray objectAtIndex:indexPath.row];
        
        if (!photo.photographerName) {
            cell.nameLabel.text = @"Loading...";
        } else cell.nameLabel.text = photo.photographerName;
        
        if (photo.photographerImage == nil) { // Fetch photographer image
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:photo.photographerImageURLString] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                
                NSData *imageData = [[NSData alloc] initWithContentsOfURL:location];
                UIImage *photographerImage = [UIImage imageWithData:imageData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.photographerImageView.image = photographerImage;
                    photo.photographerImage = photographerImage;
                });
            }];
            [task resume];
        } else {
            cell.photographerImageView.image = photo.photographerImage;
        }
        
        if (photo.image == nil) { // Fetch image
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:photo.imageURLString] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                
                NSData *imageData = [[NSData alloc] initWithContentsOfURL:location];
                UIImage *photoImage = [UIImage imageWithData:imageData];
                
                if (photoImage.size.height > photoImage.size.width) {
                    
                    CGSize photoWidth = CGSizeMake(photoImage.size.width, photoImage.size.width);
                    photoImage = [UIImage cropToSquare:photoImage scaledToFillSize:photoWidth];
                } else if (photoImage.size.height < photoImage.size.width) {
                    
                    CGSize photoHeight = CGSizeMake(photoImage.size.height, photoImage.size.height);
                    photoImage = [UIImage cropToSquare:photoImage scaledToFillSize:photoHeight];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.photoImageView.image = photoImage;
                    photo.image = photoImage;
                });
            }];
            [task resume];
        } else {
            cell.photoImageView.image = photo.image;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.photoArray.count > 0) {
        Photo *photo = [self.photoArray objectAtIndex:indexPath.row];
        
        PhotoTableViewCell *photoCell = (PhotoTableViewCell*)cell;
        photoCell.photoImageView.image = photo.image;
        photoCell.photographerImageView.image = photo.photographerImage;
    }
}

#pragma mark Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Autolayout

- (void)setConstraintsForNameLabel:(UILabel*)label andPhotographerImageView:(UIImageView*)photographerView andPhotoView:(UIImageView*)photoView onCell:(UITableViewCell*)cell
{
    label.translatesAutoresizingMaskIntoConstraints = NO;
    photographerView.translatesAutoresizingMaskIntoConstraints = NO;
    photoView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Photo
    // align photoView from the left and right
    [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[photoView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(photoView)]];
    
    // align photoView from the bottom
    [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-80-[photoView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(photoView)]];
    
    // PhotographerView
    [cell addConstraint:
     [NSLayoutConstraint constraintWithItem:photographerView
                                  attribute:NSLayoutAttributeTop
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:cell
                                  attribute:NSLayoutAttributeTop
                                 multiplier:1.0
                                   constant:10.0f]];
    
    [cell addConstraint:
     [NSLayoutConstraint constraintWithItem:photographerView
                                  attribute:NSLayoutAttributeLeft
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:cell
                                  attribute:NSLayoutAttributeLeft
                                 multiplier:1.0
                                   constant:10.0f]];
    
    
    [cell addConstraint:
     [NSLayoutConstraint constraintWithItem:photographerView
                                  attribute:NSLayoutAttributeHeight
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:photographerView
                                  attribute:NSLayoutAttributeWidth
                                 multiplier:1.0
                                   constant:0.0f]];
    
    [cell addConstraint:
     [NSLayoutConstraint constraintWithItem:photographerView
                                  attribute:NSLayoutAttributeHeight
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:nil
                                  attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0
                                   constant:60.0]];
    
    // Label
    
    [cell addConstraint:
     [NSLayoutConstraint constraintWithItem:label
                                  attribute:NSLayoutAttributeLeft
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:photographerView
                                  attribute:NSLayoutAttributeRight
                                 multiplier:1.0
                                   constant:10.0]];
    
    [cell addConstraint:
     [NSLayoutConstraint constraintWithItem:label
                                  attribute:NSLayoutAttributeCenterY
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:photographerView
                                  attribute:NSLayoutAttributeCenterY
                                 multiplier:1.0
                                   constant:0.0]];
    
    [cell addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:[label]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
}


@end
