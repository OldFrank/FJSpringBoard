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
#import "FJSpringBoardAction.h"
#import "FJSpringBoardActionIndexMap.h"

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

@property(nonatomic, readwrite) CGPoint contentOffset;

@property(nonatomic, retain) NSMutableIndexSet *mutableAllIndexes;
@property(nonatomic, retain) NSMutableIndexSet *mutableLoadedIndexes;
@property (nonatomic, retain) NSMutableIndexSet *mutableIndexesToLoad;
@property (nonatomic, retain) NSMutableIndexSet *mutableIndexesToLayout;
@property (nonatomic, retain) NSMutableIndexSet *mutableIndexesToUnload;

@property (nonatomic, retain) NSIndexSet* visibleIndexes;

@property (nonatomic, retain) NSMutableArray *actionQueue;


@end


@implementation FJSpringBoardIndexLoader


@synthesize layout;
@synthesize contentOffset;

@synthesize cells;

@synthesize mutableAllIndexes;
@synthesize mutableLoadedIndexes;    
@synthesize mutableIndexesToLoad;
@synthesize mutableIndexesToLayout;
@synthesize mutableIndexesToUnload;

@synthesize visibleIndexes;

@synthesize actionQueue;


- (void) dealloc
{
    [actionQueue release];
    actionQueue = nil;
    [mutableIndexesToLoad release];
    mutableIndexesToLoad = nil;
    [mutableIndexesToLayout release];
    mutableIndexesToLayout = nil;
    [mutableIndexesToUnload release];
    mutableIndexesToUnload = nil;
    [mutableAllIndexes release];
    mutableAllIndexes = nil; 
    [cells release];
    cells = nil;
    [layout release];
    layout = nil;
    [super dealloc];
}

- (id)initWithCount:(NSUInteger)count{
    
    self = [super init];
    if (self != nil) {
        
        self.mutableAllIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)];
        self.mutableLoadedIndexes = [NSMutableIndexSet indexSet];
        self.mutableIndexesToLayout = [NSMutableIndexSet indexSet];
        self.mutableIndexesToLoad = [NSMutableIndexSet indexSet];
        self.mutableIndexesToUnload = [NSMutableIndexSet indexSet];
        
        self.cells = nullArrayOfSize(count);
        
        self.actionQueue = [NSMutableArray array];
            
        
    }
    return self;
}

- (NSIndexSet*)allIndexes{
    
    return [[self.mutableAllIndexes copy] autorelease];

}

- (void)updateIndexesWithContentOffest:(CGPoint)newOffset{
    
    self.contentOffset = newOffset;

    if([self.layout isKindOfClass:[FJSpringBoardVerticalLayout class]]){
        
        FJSpringBoardVerticalLayout* vert = (FJSpringBoardVerticalLayout*)self.layout;
        
        NSMutableIndexSet* newVisibleIndexes = [[[vert visibleCellIndexesWithPaddingForContentOffset:newOffset] mutableCopy] autorelease];
        self.visibleIndexes = newVisibleIndexes;
        
        NSIndexSet* added = indexesAdded(self.loadedIndexes, newVisibleIndexes);
        NSIndexSet* removed = indexesRemoved(self.loadedIndexes, newVisibleIndexes);
                
        [self markIndexesForLoading:added];
        [self markIndexesForUnloading:removed];
        
    }else{
        
        FJSpringBoardHorizontalLayout* hor = (FJSpringBoardHorizontalLayout*)self.layout;
        
        NSUInteger currentPage = [hor pageForContentOffset:newOffset];
        
        NSUInteger pageCount = [hor pageCount];
        
        NSUInteger nextPage = NSNotFound;
        
        if(currentPage < pageCount-1)
            nextPage = currentPage + 1;
        
        NSUInteger previousPage = NSNotFound;
        
        if(currentPage != 0)
            previousPage = currentPage - 1;
        
        NSMutableIndexSet* newIndexes = [NSMutableIndexSet indexSet];
        self.visibleIndexes = newIndexes;
        
        [newIndexes addIndexes:[hor cellIndexesForPage:currentPage]];
        [newIndexes addIndexes:[hor cellIndexesForPage:previousPage]];
        [newIndexes addIndexes:[hor cellIndexesForPage:nextPage]];
        
        NSIndexSet* added = indexesAdded(self.loadedIndexes, newIndexes);
        NSIndexSet* removed = indexesRemoved(self.loadedIndexes, newIndexes);
        
        [self markIndexesForLoading:added];
        [self markIndexesForUnloading:removed];
            
    }
    
}


- (void)markIndexesForLoading:(NSIndexSet*)indexes{
    
    [self.mutableIndexesToLoad addIndexes:indexes];
    [self markIndexesForLayout:indexes];
    [self.mutableIndexesToUnload removeIndexes:indexes];
}

- (void)markIndexesForLayout:(NSIndexSet*)indexes{
    
    [self.mutableIndexesToLayout addIndexes:indexes];
}

- (void)markIndexesForUnloading:(NSIndexSet*)indexes{
    
    [self.mutableIndexesToUnload addIndexes:indexes];
    [self.mutableIndexesToLoad removeIndexes:indexes];
    [self.mutableIndexesToLayout removeIndexes:indexes];

}

- (NSIndexSet*)indexesToLoad{
    
    return [[self.mutableIndexesToLoad copy] autorelease];
}

- (NSIndexSet*)indexesToLayout{
    
    return [[self.mutableIndexesToLayout copy] autorelease];

}

- (NSIndexSet*)indexesToUnload{
    
    return [[self.mutableIndexesToUnload copy] autorelease];

}

- (void)clearIndexesToLoad{
    
    [self.mutableLoadedIndexes addIndexes:self.mutableIndexesToLoad];
    [self.mutableIndexesToLoad removeAllIndexes];
}

- (void)clearIndexesToLayout{
    
    [self.mutableIndexesToLayout removeAllIndexes];

}

- (void)clearIndexesToUnload{
    
    [self.mutableLoadedIndexes removeIndexes:self.mutableIndexesToUnload];
    [self.mutableIndexesToUnload removeAllIndexes];

}

- (NSIndexSet*)loadedIndexes{
    
    return [[self.mutableLoadedIndexes copy] autorelease];

}


- (void)addToActionQueue:(id)actionQueueObject
{
    [[self actionQueue] addObject:actionQueueObject];
}
- (void)removeFromActionQueue:(id)actionQueueObject
{
    [[self actionQueue] removeObject:actionQueueObject];
}


- (void)queueActionByReloadingCellsAtIndexes:(NSIndexSet*)indexes withAnimation:(FJSpringBoardCellAnimation)animation{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    
        FJSpringBoardAction* a = [FJSpringBoardAction actionForReloadingCellAtIndex:idx animation:animation];
        [self addToActionQueue:a];
        
    }];
    
}
- (void)queueActionByMovingCellAtIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex withAnimation:(FJSpringBoardCellAnimation)animation{
    
    FJSpringBoardAction *a = [FJSpringBoardAction actionForMovingCellAtIndex:startIndex toIndex:endIndex animation:animation];
    [self addToActionQueue:a];
    
}
- (void)queueActionByInsertingCellsAtIndexes:(NSIndexSet*)indexes withAnimation:(FJSpringBoardCellAnimation)animation{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        FJSpringBoardAction* a = [FJSpringBoardAction actionForInsertingCellAtIndex:idx animation:animation];
        [self addToActionQueue:a];
        
    }];
    
}
- (void)queueActionByDeletingCellsAtIndexes:(NSIndexSet*)indexes withAnimation:(FJSpringBoardCellAnimation)animation{
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
       
        FJSpringBoardAction* a = [FJSpringBoardAction actionForDeletingCellAtIndex:idx animation:animation];
        [self addToActionQueue:a];
        
    }];
    
}

- (NSArray*)animationsByProcessingActionQueue{
    
    
    ASSERT_TRUE(indexesAreContiguous(self.visibleIndexes));
    
    NSRange range = rangeWithContiguousIndexes(self.visibleIndexes);
    FJSpringBoardActionIndexMap* map = [[FJSpringBoardActionIndexMap alloc] initWithCellCount:[self.allIndexes count] actionableIndexRange:range springBoardActions:self.actionQueue];
    
    NSArray* actions = [map mappedCellActions];
        
    //TODO: need to get new count so we can update the layout
    
    
    
    
}



@end
