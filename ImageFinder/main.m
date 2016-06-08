//
//  main.m
//  ImageFinder
//
//  Created by Jae Hee Cho on 2016-06-07.
//  Copyright © 2016 Jae Hee Cho. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AppKit;

#define THUMBNAIL_SAVE_PATH @"/Users/jaeheecho/Desktop/thumbnails"

void getImageWithOperation(NSFileManager *manager, NSDirectoryEnumerator *enumerator, NSOperationQueue *operationQueue, NSURL *path) {
    
    for (NSURL *fileURL in enumerator) {
        NSString *filename;
        [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];
        
        NSNumber *isDirectory;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        
        NSNumber *isHidden;
        [fileURL getResourceValue:&isHidden forKey:NSURLIsHiddenKey error:nil];
        
        if ([isDirectory boolValue] && ![isHidden boolValue]) {
            // Since enumerator is set to skip subdirectories, create next enumerator that will be enqueued to operation queue
            NSDirectoryEnumerator *nextEnumerator = [manager enumeratorAtURL:fileURL includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
                if (error) {
                    NSLog(@"[Error] %@ (%@)", error, url);
                    return NO;
                }
                return YES;
            }];
            
            // Enqueue next iteration(subdirectory traversing) to operation queue to maximize the performance
            [operationQueue addOperationWithBlock:^{
                getImageWithOperation(manager, nextEnumerator, operationQueue, fileURL);
            }];
            
            continue;
        } else if (![isHidden boolValue]) {
            //Check if fileURL is an image
            NSString *pathString = [[fileURL absoluteString] stringByRemovingPercentEncoding];
            
            // trimming first 7 letters: "file://"
            pathString = [pathString substringFromIndex:7];
            CFStringRef fileExtension = (__bridge CFStringRef) [pathString pathExtension];
            CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
            
            if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
                NSImage *originalImage = [[NSImage alloc]initWithContentsOfFile:pathString];
                if (originalImage == nil) {
                    NSLog(@"image nil: %@", pathString);
                } else {
                    //needs to create thumbnails
//                    NSImage *smallImage = [[NSImage alloc]initWithSize:NSMakeSize(32, 32)];
//                    NSSize originalSize = [originalImage size];
//                    NSRect fromRect = NSMakeRect(0, 0, originalSize.width, originalSize.height);
//                    [smallImage lockFocus];
//                    [originalImage drawInRect:NSMakeRect(0, 0, 32, 32) fromRect:fromRect operation:NSCompositeCopy fraction:1.0f];
//                    [smallImage unlockFocus];
//                    
//                    
//                    CGImageRef cgRef = [smallImage CGImageForProposedRect:NULL
//                                                             context:nil
//                                                               hints:nil];
//                    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
//                    [newRep setSize:[smallImage size]];   // if you want the same resolution
//                    NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:nil];
//                    [pngData writeToFile:[NSString stringWithFormat:@"%@/%@", THUMBNAIL_SAVE_PATH, pathString] atomically:YES];
                    
                    NSLog(@"Image: %@", pathString);
                }
            }
        }
    }
}

//void getImageWithGCD(NSFileManager *manager, NSDirectoryEnumerator *enumerator, dispatch_queue_t queue, NSString *path) {
//    NSString *entry;
//    while ((entry = [enumerator nextObject]) != nil) {
//        BOOL isDirectory;
//        
//    }
//}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSString *rootDirectory;
        
        char input[100];
        
        scanf("%s", input);
        rootDirectory = [NSString stringWithCString:input encoding:1];
        
        while ([fileManager changeCurrentDirectoryPath:rootDirectory] == NO) {
            NSLog(@"Invalid directory entry: %@", rootDirectory);
            NSLog(@"Please Enter correct root directory: ");
            scanf("%s", input);
            rootDirectory = [NSString stringWithCString:input encoding:1];
        }
        
        NSURL *rootUrl = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", rootDirectory]];
        
        NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:rootUrl includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
                if (error) {
                    NSLog(@"[Error] %@ (%@)", error, url);
                    return NO;
                }
                return YES;
            }];
        
        NSOperationQueue *operationQueue = [NSOperationQueue new];
//        dispatch_queue_t dispatchQueue = dispatch_get_global_queue(0, 0);
        
        getImageWithOperation(fileManager, enumerator, operationQueue, rootUrl);
        
        char temp[40];
        scanf("%s", temp);
    }
    return 0;
}
