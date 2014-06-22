// OPFlickrCommonsProvider.m
// 
// Copyright (c) 2013 Say Goodnight Software
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "OPFlickrProvider.h"
#import "AFFlickrSessionManager.h"
#import "OPImageItem.h"
#import "OPProviderTokens.h"

@interface OPFlickrProvider ()

@end

@implementation OPFlickrProvider

- (BOOL) isConfigured {
#ifndef kOPPROVIDERTOKEN_FLICKR
#warning *** WARNING: Make sure you have added your Flickr token to OPProviderTokens.h!
    return NO;
#else
    return YES;
#endif
}

- (void) doInitialSearchWithUserId:(NSString*)userId
                         isCommons:(BOOL)isCommons
                           success:(void (^)(NSArray* items, BOOL canLoadMore))success
                           failure:(void (^)(NSError* error))failure {
    
    [self getItemsWithQuery:@""
             withPageNumber:@1
                 withUserId:userId
                  isCommons:isCommons
                    success:success
                    failure:failure];
}

- (NSString*) getHighestResUrlFromDictionary:(NSDictionary*) dict {
    if (dict[@"url_o"]) {
        return dict[@"url_o"];
    } else if (dict[@"url_b"]) {
        return dict[@"url_b"];
    } else if (dict[@"url_l"]) {
        return dict[@"url_l"];
    } else if (dict[@"url_m"]) {
        return dict[@"url_m"];
    } else if (dict[@"url_s"]) {
        return dict[@"url_s"];
    }
    
    return nil;
}

- (void) getImageSetsWithPageNumber:(NSNumber*) pageNumber
                         withUserId:(NSString*) userId
                            success:(void (^)(NSArray* items, BOOL canLoadMore))success
                            failure:(void (^)(NSError* error))failure {
    NSMutableDictionary* parameters = @{
                                        @"page": pageNumber,
                                        @"nojsoncallback": @"1",
                                        @"method" : @"flickr.photosets.getlist",
                                        @"format" : @"json",
                                        @"primary_photo_extras": @"url_b,url_o,o_dims,url_m,url_s",
                                        @"per_page": @"20"
                                        }.mutableCopy;
    
    if (userId) {
        parameters[@"user_id"] = userId;
    }
    
    [[AFFlickrSessionManager sharedClient] GET:@"services/rest" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        
        NSDictionary* photosetsDict = responseObject[@"photosets"];
        NSMutableArray* retArray = [NSMutableArray array];
        NSArray* photosetArray = photosetsDict[@"photoset"];
        for (NSDictionary* itemDict in photosetArray) {
            NSString* imageUrlString = [self getHighestResUrlFromDictionary:itemDict[@"primary_photo_extras"]];
            NSMutableDictionary* opImageDict = @{
                                                 @"imageUrl": [NSURL URLWithString:imageUrlString],
                                                 @"title" : [itemDict valueForKeyPath:@"title._content"],
                                                 @"providerType": self.providerType,
                                                 @"providerSpecific": itemDict,
                                                 @"isImageSet": @YES
                                                 }.mutableCopy;
            
            if ([itemDict valueForKeyPath:@"primary_photo_extras.width_o"]) {
                opImageDict[@"width"] = [itemDict valueForKeyPath:@"primary_photo_extras.width_o"];
            }
            if ([itemDict valueForKeyPath:@"primary_photo_extras.height_o"]) {
                opImageDict[@"height"] = [itemDict valueForKeyPath:@"primary_photo_extras.height_o"];
            }
            
            OPImageItem* item = [[OPImageItem alloc] initWithDictionary:opImageDict];
            [retArray addObject:item];
        }
        
        BOOL returnCanLoadMore = NO;
        NSInteger thisPage = [photosetsDict[@"page"] integerValue];
        NSInteger totalPages = [photosetsDict[@"pages"] integerValue];
        if (thisPage < totalPages) {
            returnCanLoadMore = YES;
        }
        
        if (success) {
            success(retArray,returnCanLoadMore);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
        NSLog(@"ERROR: %@\n%@\n%@", error.localizedDescription,error.localizedFailureReason,error.localizedRecoverySuggestion);
    }];
}

- (void) parseResponseDictionary:(NSDictionary*) dict
                         success:(void (^)(NSArray* items, BOOL canLoadMore))success {
    NSArray* photoArray = dict[@"photo"];
    NSMutableArray* retArray = @[].mutableCopy;
    for (NSDictionary* itemDict in photoArray) {
        NSString* farmId = itemDict[@"farm"];
        NSString* serverId = itemDict[@"server"];
        NSString* photoId = itemDict[@"id"];
        NSString* photoSecret = itemDict[@"secret"];
        
        NSString* imageUrlString = [NSString stringWithFormat:@"https://farm%@.staticflickr.com/%@/%@_%@.jpg",farmId,serverId,photoId,photoSecret];
        NSMutableDictionary* opImageDict = @{
                                             @"imageUrl": [NSURL URLWithString:imageUrlString],
                                             @"title" : itemDict[@"title"],
                                             @"providerType": self.providerType,
                                             @"providerSpecific": itemDict,
                                             }.mutableCopy;
        
        if (itemDict[@"width_o"]) {
            opImageDict[@"width"] = itemDict[@"width_o"];
        }
        if (itemDict[@"height_o"]) {
            opImageDict[@"height"] = itemDict[@"height_o"];
        }
        
        OPImageItem* item = [[OPImageItem alloc] initWithDictionary:opImageDict];
        [retArray addObject:item];
    }
    
    BOOL returnCanLoadMore = NO;
    NSInteger thisPage = [dict[@"page"] integerValue];
    NSInteger totalPages = [dict[@"pages"] integerValue];
    if (thisPage < totalPages) {
        returnCanLoadMore = YES;
    }
    
    if (success) {
        success(retArray,returnCanLoadMore);
    }
}

- (void) getItemsInSetWithId:(NSString*) setId
              withPageNumber:(NSNumber*) pageNumber
                     success:(void (^)(NSArray* items, BOOL canLoadMore))success
                     failure:(void (^)(NSError* error))failure {
    NSMutableDictionary* parameters = @{
                                        @"photoset_id": setId,
                                        @"page": pageNumber,
                                        @"nojsoncallback": @"1",
                                        @"method" : @"flickr.photosets.getphotos",
                                        @"format" : @"json",
                                        @"extras": @"url_b,url_o,o_dims,url_l",
                                        @"per_page": @"20"
                                        }.mutableCopy;
    
    [[AFFlickrSessionManager sharedClient] GET:@"services/rest" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary* photosDict = responseObject[@"photoset"];
        [self parseResponseDictionary:photosDict success:success];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
        NSLog(@"ERROR: %@\n%@\n%@", error.localizedDescription,error.localizedFailureReason,error.localizedRecoverySuggestion);
    }];
}

- (void) getItemsWithQuery:(NSString*) queryString
            withPageNumber:(NSNumber*) pageNumber
                withUserId:(NSString*) userId
                 isCommons:(BOOL)isCommons
                   success:(void (^)(NSArray* items, BOOL canLoadMore))success
                   failure:(void (^)(NSError* error))failure {
    
    NSMutableDictionary* parameters = @{
                                 @"text" : queryString,
                                 @"page": pageNumber,
                                 @"nojsoncallback": @"1",
                                 @"method" : @"flickr.photos.search",
                                 @"format" : @"json",
                                 @"extras": @"url_b,url_o,o_dims,url_l",
                                 @"per_page": @"20"
                                 }.mutableCopy;
    
    if (isCommons) {
        parameters[@"is_commons"] = @"true";
    }
    
    if (userId) {
        parameters[@"user_id"] = userId;
    }
    
    [[AFFlickrSessionManager sharedClient] GET:@"services/rest" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary* photosDict = responseObject[@"photos"];
        [self parseResponseDictionary:photosDict success:success];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
        NSLog(@"ERROR: %@\n%@\n%@", error.localizedDescription,error.localizedFailureReason,error.localizedRecoverySuggestion);
    }];
}

- (void) upRezItem:(OPImageItem *) item withCompletion:(void (^)(NSURL *uprezImageUrl, OPImageItem* item))completion {

    NSString* upRezzedUrlString = item.imageUrl.absoluteString;
    
    if (item.providerSpecific[@"url_o"]) {
        upRezzedUrlString = item.providerSpecific[@"url_o"];
    } else if (item.providerSpecific[@"url_b"]) {
        upRezzedUrlString = item.providerSpecific[@"url_b"];
    } else if (item.providerSpecific[@"url_l"]) {
        upRezzedUrlString = item.providerSpecific[@"url_l"];
    }

    if (completion && ![upRezzedUrlString isEqualToString:item.imageUrl.absoluteString]) {
        completion([NSURL URLWithString:upRezzedUrlString], item);
    }
}

@end
