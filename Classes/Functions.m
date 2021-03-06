
#import "Functions.h"
#include <sys/xattr.h>




BOOL rangesAreContiguous(NSRange first, NSRange second){
    
    NSIndexSet* firstIndexes = [NSIndexSet indexSetWithIndexesInRange:first];
    NSIndexSet* secondIndexes = [NSIndexSet indexSetWithIndexesInRange:second];
    
    NSUInteger endOfFirstRange = [firstIndexes lastIndex];
    NSUInteger beginingOfSecondRange = [secondIndexes firstIndex];
    
    if(beginingOfSecondRange - endOfFirstRange == 1)
        return YES;
    
    return NO;
    
}

NSRange rangeWithFirstAndLastIndexes(NSUInteger first, NSUInteger last){
    
    if(last < first)
        return NSMakeRange(0, 0);
    
    if(first == NSNotFound || last == NSNotFound)
        return NSMakeRange(0, 0);
    
    NSUInteger length = last-first + 1;
    
    NSRange r = NSMakeRange(first, length);
    return r;
    
}


float nanosecondsWithSeconds(float seconds){
    
    return (seconds * 1000000000);
    
}

dispatch_time_t dispatchTimeFromNow(float seconds){
    
    return  dispatch_time(DISPATCH_TIME_NOW, nanosecondsWithSeconds(seconds));
    
}

BOOL addSkipBackupAttributeToItemAtURL(NSURL *URL){
    
    const char* filePath = [[URL path] fileSystemRepresentation];
    
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}

NSUInteger sizeOfFolderContentsInBytes(NSString* folderPath){
    
    NSError* error = nil;
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:&error];
    
    if (error != nil){
        return NSNotFound;
    }
    
    double bytes = 0.0;
    for(NSString* eachFile in contents){
        
        NSDictionary* meta = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:eachFile] error:&error];
        
        if(error != nil){
            
            break;
        }
        
        NSNumber* fileSize = [meta objectForKey:NSFileSize];
        bytes += [fileSize unsignedIntegerValue];
    } 
    
    if(error != nil){
        
        return NSNotFound;
    }
    
    return bytes;
    
}


double megaBytesWithBytes(long long bytes){
    
    NSNumber* b = [NSNumber numberWithLongLong:bytes];
    
    double bytesAsDouble = [b doubleValue];
    
    double mb = bytesAsDouble/1048576.0;
    
    return mb;
    
}



void dispatchOnMainQueue(dispatch_block_t block){
    
    dispatch_async(dispatch_get_main_queue(), block);
}

void dispatchOnMainQueueAfterDelayInSeconds(float delay, dispatch_block_t block){
    
    dispatchAfterDelayInSeconds(delay, dispatch_get_main_queue(), block);    
}

void dispatchAfterDelayInSeconds(float delay, dispatch_queue_t queue, dispatch_block_t block){
    
    dispatch_after(dispatchTimeFromNow(delay), queue, block);
    
}


Progress progressMake(unsigned long long complete, unsigned long long total){
    
    if(total == 0)
        return kProgressZero;
    
    Progress p;
    
    p.total = total;
    p.complete = complete;
    
    NSNumber* t = [NSNumber numberWithLongLong:total];
    NSNumber* c = [NSNumber numberWithLongLong:complete];
    
    double r = [c doubleValue]/[t doubleValue];
    
    p.ratio = r;
    
    return p;
}


Progress const kProgressZero = {
    0,
    0,
    0.0
};
