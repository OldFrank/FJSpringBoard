//
//  FJSpringBoardIndexLoader.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardIndexLoader.h"
#import "FJSpringBoardVerticalLayout.h"
#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardLayout.h"
#import "FJSpringBoardUtilities.h"
#import "FJSpringBoardCell.h"

#define MAX_PAGES 3

NSUInteger indexWithLargestAbsoluteValueFromStartignIndex(NSUInteger start, NSIndexSet* indexes){
    
    __block NSUInteger answer = start;
    __block int largestDiff = 0;
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    
        int diff = abs((int)((int)start - (int)idx));
        
        if(diff > largestDiff){
            largestDiff = diff;
            answer = idx;
        }
        
    }];
    
    return answer;
}

@interface FJSpringBoardIndexLoader()

@property(nonatomic, readwrite) IndexRangeChanges lastChangeSet;
@property(nonatomic, readwrite) CGPoint contentOffset;
@property(nonatomic, retain) NSMutableIndexSet *currentPages;
@property(nonatomic, readwrite) NSUInteger originalReorderingIndex;
@property(nonatomic, readwrite) NSUInteger currentReorderingIndex;

- (IndexRangeChanges)horizontalChnagesBySettingContentOffset:(CGPoint)offset;
- (IndexRangeChanges)verticalChnagesBySettingContentOffset:(CGPoint)offset;


@end


@implementation FJSpringBoardIndexLoader

@synthesize allIndexes;

@synthesize layout;
@synthesize lastChangeSet;
@synthesize contentOffset;
@synthesize currentIndexes;    
@synthesize currentPages;

@synthesize mapNewToOld;
@synthesize mapOldToNew;
@synthesize cellsWithoutCurrentChangesApplied;
@synthesize cells;
@synthesize originalReorderingIndex;
@synthesize currentReorderingIndex;


- (void) dealloc
{
    [allIndexes release];
    allIndexes = nil; 
    [mapOldToNew release];
    mapOldToNew = nil;
    [cellsWithoutCurrentChangesApplied release];
    cellsWithoutCurrentChangesApplied = nil;
    [cells release];
    cells = nil;
    [mapNewToOld release];
    mapNewToOld = nil;
    [layout release];
    layout = nil;
    [currentPages release];
    currentPages = nil;
    [currentIndexes release];
    currentIndexes = nil;
    [super dealloc];
}

- (id)initWithCount:(NSUInteger)count{
    
    self = [super init];
    if (self != nil) {
        self.allIndexes = [NSMutableIndexSet indexSet];
        self.currentPages = [NSMutableIndexSet indexSet];
        self.currentIndexes = [NSMutableIndexSet indexSet];
        self.cells = nullArrayOfSize(count);
        self.allIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)];

        [self commitChanges];
        
    }
    return self;
}


- (IndexRangeChanges)changesBySettingContentOffset:(CGPoint)offset{
        
    if([self.cells count] != [self.allIndexes count]){
        
        ALWAYS_ASSERT;
    }
    
    if([self.layout isKindOfClass:[FJSpringBoardVerticalLayout class]])
        return [self verticalChnagesBySettingContentOffset:offset];
    else
        return [self horizontalChnagesBySettingContentOffset:offset];
    
}

- (IndexRangeChanges)verticalChnagesBySettingContentOffset:(CGPoint)offset{
    
    FJSpringBoardVerticalLayout* vert = (FJSpringBoardVerticalLayout*)self.layout;
    
    NSMutableIndexSet* newVisibleIndexes = [[[vert visibleCellIndexesWithPaddingForContentOffset:offset] mutableCopy] autorelease];
    
    NSIndexSet* addedIndexes = indexesAdded(self.currentIndexes, newVisibleIndexes);
    
    if([addedIndexes count] == 0){
        
        return indexRangeChangesMake(NSMakeRange(0, 0), NSMakeRange(0, 0), NSMakeRange(0, 0));
        
    } 
    
    if(!indexesAreContinuous(addedIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    NSRange addedRange = rangeWithIndexes(addedIndexes);
    
    
    
    NSIndexSet* removedIndexes = indexesRemoved(self.currentIndexes, newVisibleIndexes);
    
    if(!indexesAreContinuous(removedIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    NSRange removedRange = rangeWithIndexes(removedIndexes);
    
    NSRange totalRange = rangeWithIndexes(newVisibleIndexes);
    
    IndexRangeChanges changes = indexRangeChangesMake(totalRange, addedRange, removedRange);
    
    self.contentOffset = offset;
    self.lastChangeSet = changes;
    self.currentIndexes = newVisibleIndexes;
    
    [newVisibleIndexes release];
    
    return changes;
    
}


- (IndexRangeChanges)horizontalChnagesBySettingContentOffset:(CGPoint)offset{
    
    FJSpringBoardHorizontalLayout* hor = (FJSpringBoardHorizontalLayout*)self.layout;
    
    NSUInteger currentPage = [hor pageForContentOffset:offset];
    
    NSUInteger nextPage = [hor nextPageWithPreviousContentOffset:self.contentOffset currentContentOffset:offset];
    
    NSUInteger pageCount = [hor pageCount];
    
    NSIndexSet* pageIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, pageCount)];
    
    if(abs((int)(currentPage-nextPage) > 1)){
        
        ALWAYS_ASSERT;
    }
    
    if([self.currentPages count] > 0 && ![self.currentPages containsIndex:currentPage]){
        
        ALWAYS_ASSERT;
    }
    
    if([self.currentPages count] == 0){
        
        //first load
        if(pageCount > 1)
            nextPage = 1;
        
    }   

   
    
    [self.currentPages addIndex:currentPage];
    [self.currentPages addIndex:nextPage];
    
    NSUInteger rightPage = currentPage+1;
    NSUInteger leftPage = currentPage-1;
    
    if([pageIndexes containsIndex:leftPage])
        [self.currentPages addIndex:leftPage];
    
    if([pageIndexes containsIndex:rightPage])
        [self.currentPages addIndex:rightPage];

         
    //removed pages
    if([self.currentPages count] > MAX_PAGES){
        
        NSUInteger pageToKill = indexWithLargestAbsoluteValueFromStartignIndex(currentPage, self.currentPages);
        [self.currentPages removeIndex:pageToKill];
        
    }

    //total indexes
    NSMutableIndexSet* totalIndexes = [NSMutableIndexSet indexSet];
    [self.currentPages enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    
        NSIndexSet* pIndexes = [hor cellIndexesForPage:idx];
        [totalIndexes addIndexes:pIndexes];
    
    }];
    
    NSIndexSet* addedIndexes = indexesAdded(self.currentIndexes, totalIndexes);
    NSIndexSet* removedIndexes = indexesRemoved(self.currentIndexes, totalIndexes);

    
    if([addedIndexes count] > 0 && !indexesAreContinuous(addedIndexes)){
        
        ALWAYS_ASSERT;
    }    
    
    if([removedIndexes count] > 0 && !indexesAreContinuous(removedIndexes)){
        
        ALWAYS_ASSERT;
    }
    
    if([addedIndexes count] > 0 && !indexesAreContinuous(totalIndexes)){
        
        ALWAYS_ASSERT;
    }   
    
    //NSLog(@"total indexes: %@", [totalIndexes description]);
    //NSLog(@"pages to load: %@", [pages description]);
    //NSLog(@"indexes to add: %@", [addedIndexes description]);
    //NSLog(@"indexes to remove: %@", [indexesToRemove description]);
    
      
    
    NSRange addedRange = rangeWithIndexes(addedIndexes);
    
    NSRange removedRange = rangeWithIndexes(removedIndexes);
    
    NSRange totalRange = rangeWithIndexes(totalIndexes);
    
    IndexRangeChanges changes = indexRangeChangesMake(totalRange, addedRange, removedRange);
    
    self.contentOffset = offset;
    self.lastChangeSet = changes;
    self.currentIndexes = totalIndexes;
    
    return changes;
    
    
}


- (NSUInteger)newIndexForOldIndex:(NSUInteger)oldIndex{
    
    NSNumber* newNum = [self.mapOldToNew objectAtIndex:oldIndex];
    
    return [newNum unsignedIntegerValue];
    
    
}
- (NSUInteger)oldIndexForNewIndex:(NSUInteger)newIndex{
    
    NSNumber* newNum = [self.mapNewToOld objectAtIndex:newIndex];
    
    return [newNum unsignedIntegerValue];
}


- (void)beginReorderingIndex:(NSUInteger)index{
    
    self.originalReorderingIndex = index;
    self.currentReorderingIndex = index;
}

- (NSIndexSet*)modifiedIndexesByMovingReorderingCellToCellAtIndex:(NSUInteger)index{
    
    if(self.currentReorderingIndex == index)
        return nil;
    
    if(index == NSNotFound)
        return nil;
    if(self.currentReorderingIndex == NSNotFound)
        return nil;
    
    id obj = [[self.cells objectAtIndex:self.currentReorderingIndex] retain];
    [self.cells removeObjectAtIndex:self.currentReorderingIndex];
    [self.cells insertObject:obj atIndex:index];
    [obj release];
    
    obj = [[self.mapNewToOld objectAtIndex:self.currentReorderingIndex] retain];
    [self.mapNewToOld removeObjectAtIndex:self.currentReorderingIndex];
    [self.mapNewToOld insertObject:obj atIndex:index];
    [obj release];
    
    obj = [[self.mapOldToNew objectAtIndex:index] retain];
    [self.mapOldToNew removeObjectAtIndex:index];
    [self.mapOldToNew insertObject:obj atIndex:self.currentReorderingIndex];
    [obj release];
    
    
    NSLog(@"moving from index: %i to index: %i", self.currentReorderingIndex, index);
    
    NSUInteger startIndex = NSNotFound;
    NSUInteger lastIndex = NSNotFound;
    
    //moving forward
    if(index > self.currentReorderingIndex){
        
        startIndex = self.currentReorderingIndex;
        lastIndex = index;
        
        //backwards    
    }else{
        
        startIndex = index;
        lastIndex = self.currentReorderingIndex;
        
    }
    
    self.currentReorderingIndex = index;
    
    NSIndexSet* affectedIndexes = contiguousIndexSetWithFirstAndLastIndexes(startIndex, lastIndex); 
    
    return affectedIndexes;
    
}

- (NSIndexSet*)modifiedIndexesByAddingGroupCell:(FJSpringBoardGroupCell*)groupCell atIndex:(NSUInteger)index{
    
    if(index == NSNotFound)
        return nil;
    
    //insert group cell
    [self.cells insertObject:groupCell atIndex:index];
    [self.mapNewToOld insertObject:[NSNumber numberWithUnsignedInt:NSNotFound] atIndex:index];
    
    NSMutableArray* editedValues = [NSMutableArray arrayWithCapacity:[self.mapOldToNew count]];
    
    [self.mapOldToNew enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSNumber* val = (NSNumber*)obj;
        
        NSUInteger oldVal = [val unsignedIntegerValue];
        
        if(oldVal != NSNotFound){
            
            if(oldVal >= index){
                oldVal++;
                
                val = [NSNumber numberWithUnsignedInteger:oldVal];
                
            }
        }
        
        [editedValues addObject:val];
        
    }];
    
    self.mapOldToNew = editedValues;
    
    [self.allIndexes addIndex:([self.allIndexes lastIndex]+1)];

    self.layout.cellCount = [self.cells count];
    [self.layout updateLayout];
    [self changesBySettingContentOffset:self.contentOffset];
    
    
    NSRange affectedRange = NSMakeRange(index, [self.cells count] - index);
    NSIndexSet* affectedIndexes = [NSIndexSet indexSetWithIndexesInRange:affectedRange]; 
    
    return affectedIndexes;
    
    
}

- (NSIndexSet*)modifiedIndexesByRemovingCellsAtIndexes:(NSIndexSet*)indexes{
    
    if([indexes count] == 0)
        return nil;
    
    NSMutableArray* nulls = [NSMutableArray arrayWithCapacity:[indexes count]];
    
    for(int i = 0; i< [indexes count]; i++){
        
        [nulls addObject:[NSNumber numberWithUnsignedInt:NSNotFound]];
    }
    
    
    NSMutableIndexSet* oldIndexes = [NSMutableIndexSet indexSet];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        NSUInteger old = [self oldIndexForNewIndex:idx];
        [oldIndexes addIndex:old];    
    }];
    
    [self.mapOldToNew replaceObjectsAtIndexes:oldIndexes withObjects:nulls];
    
    NSMutableArray* editedValues = [NSMutableArray arrayWithCapacity:[self.mapOldToNew count]];
    
    [self.mapOldToNew enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSNumber* val = (NSNumber*)obj;
        
        NSUInteger oldVal = [val unsignedIntegerValue];
        
        if(oldVal != NSNotFound){
            
            __block int numToDecrement = 0;
            
            [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                
                if(oldVal > idx)
                    numToDecrement++;
            }];
            
            oldVal = oldVal-numToDecrement;
            
            val = [NSNumber numberWithUnsignedInteger:oldVal];
            
        }
        
        
        [editedValues addObject:val];
        
    }];
    
    self.mapOldToNew = editedValues;
    
    /*
     for (int i = 0; i < [indexes count]; i++) {
     [self.mapOldToNew removeLastObject];
     }
     */
    
    //remove cells
    [self.cells removeObjectsAtIndexes:indexes];
    [self.mapNewToOld removeObjectsAtIndexes:indexes];
    
    for(int i = 0; i < [indexes count]; i++)
        [self.allIndexes removeIndex:[self.allIndexes lastIndex]];

    
    self.layout.cellCount = [self.cells count];
    [self.layout updateLayout];
    [self changesBySettingContentOffset:self.contentOffset];
        
    NSUInteger min = [indexes firstIndex];
    NSRange affectedRange = NSMakeRange(min, [self.cells count] - min);
    NSIndexSet* affectedIndexes = [NSIndexSet indexSetWithIndexesInRange:affectedRange]; 
    
    return affectedIndexes;
    
}

- (NSIndexSet*)modifiedIndexesByAddingCellsAtIndexes:(NSIndexSet*)indexes{
    
    
    if([indexes count] == 0)
        return nil;
    
    NSArray* nulls = nullArrayOfSize([indexes count]);
    
    
    //insert cells
    [self.cells insertObjects:nulls atIndexes:indexes];
    
    NSMutableArray* notfounds = [NSMutableArray arrayWithCapacity:[indexes count]];
    
    for(int i = 0; i< [indexes count]; i++){
        
        [notfounds addObject:[NSNumber numberWithUnsignedInt:NSNotFound]];
    }
    
    
    [self.mapNewToOld insertObjects:notfounds atIndexes:indexes];
    
    
    NSMutableArray* editedValues = [NSMutableArray arrayWithCapacity:[self.mapOldToNew count]];
    
    [self.mapOldToNew enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSNumber* val = (NSNumber*)obj;
        
        NSUInteger oldVal = [val unsignedIntegerValue];
        
        if(oldVal != NSNotFound){
            
            NSUInteger numberOfInsertedCellsBeforeIndex = [[indexes indexesPassingTest:^(NSUInteger idx, BOOL *stop) {
                
                if(oldVal >= idx)
                    return YES;
                
                return NO;
                
            }] count];
            
            
            oldVal+=numberOfInsertedCellsBeforeIndex;
            
            val = [NSNumber numberWithUnsignedInteger:oldVal];
            
        }
        
        [editedValues addObject:val];
        
    }];
    
    self.mapOldToNew = editedValues;
        
    for(int i = 0; i < [indexes count]; i++){
        
        NSUInteger nextIndex = [self.allIndexes lastIndex];
        
        if(nextIndex == NSNotFound){
            
            nextIndex = 0;
   
        }else{
            
            nextIndex++;
        }
        
        [self.allIndexes addIndex:(nextIndex)];

    }

    self.layout.cellCount = [self.cells count];
    [self.layout updateLayout];
    [self changesBySettingContentOffset:self.contentOffset];
    
    NSUInteger min = [indexes firstIndex];
    NSRange affectedRange = NSMakeRange(min, [self.cells count] - min);
    NSIndexSet* affectedIndexes = [NSIndexSet indexSetWithIndexesInRange:affectedRange]; 
    
    return affectedIndexes;
    
    
}


- (void)commitChanges{
    
    self.cellsWithoutCurrentChangesApplied = [[self.cells copy] autorelease];
    self.currentReorderingIndex = NSNotFound;
    self.originalReorderingIndex = NSNotFound;
    
    self.mapNewToOld = [NSMutableArray arrayWithCapacity:[self.cells count]];
    
    [self.cellsWithoutCurrentChangesApplied enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSNumber* n = [NSNumber numberWithUnsignedInteger:idx];
        [self.mapNewToOld addObject:n];
        
    }];
    
    self.mapOldToNew = [self.mapNewToOld mutableCopy];
    
}



@end
