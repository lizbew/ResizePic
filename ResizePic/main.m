//
//  main.m
//  ResizePic
//
//  Created by vika on 5/30/16.
//  Copyright © 2016 vika. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Appkit/NSImage.h>

NSString* buildResizedImageFilePath(NSString *originalFilePath) {
    return [NSString stringWithFormat:@"%@%@%@", [originalFilePath stringByDeletingPathExtension], @"-resized.", [originalFilePath pathExtension]];
}


BOOL resizeImage(NSString* imgPath, int newWidth) {
    NSImage *img = [[NSImage alloc] initWithContentsOfFile:imgPath];
    NSString *newImgPath = buildResizedImageFilePath(imgPath);
    
    if (!img) {
        NSLog(@"Failed when open image: %@", imgPath);
        return NO;
    }
    
    NSLog(@"Resize %@ to %@", imgPath, newImgPath);
    
    //img.size may not relect the real size
    NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[img TIFFRepresentation]];
    NSSize size = NSMakeSize([rep pixelsWide], [rep pixelsHigh]);
    
    
    NSLog(@"image.size width: %f, height: %f", img.size.width, img.size.height);
    NSLog(@"img rep width: %f, height: %f", size.width, size.height);
    
    if (size.width > newWidth) {
        //scale only when image size is too large
        CGFloat newHeight = size.height * newWidth / size.width;
        NSSize newSize = NSMakeSize(newWidth, newHeight);
        [img setSize:newSize];
        
        NSImage *newImage = [[NSImage alloc] initWithSize:newSize];
        [newImage lockFocus];
        [img drawInRect:NSMakeRect(0, 0, newWidth, newHeight)];
        [newImage unlockFocus];
        
        //save to file
        NSData *data = [newImage TIFFRepresentation];
        NSBitmapImageRep *newRep = [NSBitmapImageRep imageRepWithData:data];
        NSDictionary *newProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
        data = [newRep representationUsingType:NSJPEGFileType properties:newProps];
        [data writeToFile:newImgPath atomically:YES];
    }
    
    return YES;
}

// read config from json file
NSMutableDictionary* readConfig(NSString *configFile) {
    @autoreleasepool {
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:configFile]) {
            return nil;
        }
        NSData *data = [NSData dataWithContentsOfFile:configFile];
        NSMutableDictionary *configDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        return configDict;
        
    }
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        

        if (argc == 1) {
            NSLog(@"No image provided!");
            return 0;
        }
        
        NSString* configFile = @"./config.json";
        NSMutableDictionary* config = readConfig(configFile);
        int targetWidth = 400;
        if (config) {
            NSNumber *configTargetWidth = [config objectForKey:@"targetWidth"];
            if (configTargetWidth && configTargetWidth > 0) {
                targetWidth = [configTargetWidth intValue];
            }
            
        }
        
        NSFileManager* shareFM = [NSFileManager defaultManager];
        for (int i = 1; i < argc; ++i) {
            @autoreleasepool {
                NSString* imgPath = [NSString stringWithUTF8String:argv[i]];
                if ([shareFM fileExistsAtPath: imgPath]) {
                    resizeImage(imgPath, targetWidth);
                }
            }
        }
        
    }
    return 0;
}

