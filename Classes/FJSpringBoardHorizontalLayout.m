//
//  FJSpringBoardHorizontalLayout.m
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/30/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import "FJSpringBoardHorizontalLayout.h"
#import "FJSpringBoardUtilities.h"
#import "FJSpringBoardView.h"

#define NUMBER_OF_PAGES_TO_PAD 1




@interface FJSpringBoardLayout(horizontalInternal)

@property(nonatomic, readwrite) NSUInteger numberOfRows;
@property(nonatomic, readwrite) NSUInteger cellsPerRow;

@property(nonatomic, readwrite) CGSize cellSizeWithAccesories;

@property (nonatomic) CGFloat rowWidth;

@property (nonatomic) float veritcalCellSpacing;
@property (nonatomic) float horizontalCellSpacing;

@property(nonatomic, readwrite) CGSize contentSize;

- (NSUInteger)_indexForPositon:(CellPosition)position;
- (CellPosition)_positionForCellAtIndex:(NSUInteger)index;

@end

@interface FJSpringBoardHorizontalLayout()

@property (nonatomic) NSUInteger rowsPerPage;
@property (nonatomic) NSUInteger cellsPerPage;
@property(nonatomic) CGSize pageSize;
@property(nonatomic) CGSize pageSizeWithInsetsApplied;

- (CGPoint)_originForCellAtPosition:(CellPosition)position;

- (CGFloat)_horizontalOffsetForPage:(NSUInteger)page;
- (NSUInteger)_pageForCellAtPosition:(CellPosition)position;

- (CGSize)_pageSizeWithInsetsApplied;
- (NSUInteger)_numberOfPages;

- (CGSize)_contentSize;

@end


@implementation FJSpringBoardHorizontalLayout

@synthesize rowsPerPage;
@synthesize cellsPerPage;
@synthesize pageSize;
@synthesize pageSizeWithInsetsApplied;
@synthesize pageCount;



- (void)calculateLayout{
     
    [super calculateLayout];

    self.pageSize = self.springBoardBounds.size;
    self.pageSizeWithInsetsApplied = [self _pageSizeWithInsetsApplied];
    
    float pageHeight = self.pageSizeWithInsetsApplied.height;
    float minimumCellheight = self.cellSizeWithAccesories.height;
    float rowsInOnePage = floorf(pageHeight / minimumCellheight);
    self.rowsPerPage = (NSUInteger)rowsInOnePage;
    
    self.cellsPerPage = self.rowsPerPage * self.cellsPerRow;
    
    self.veritcalCellSpacing = (pageHeight - (self.rowsPerPage * self.cellSize.height))/(self.rowsPerPage+1);
    
    self.pageCount = [self _numberOfPages];
        
    self.contentSize = [self _contentSize];

}

- (float)_rowWidth{
    
    return (self.springBoardBounds.size.width /*- self.springBoard.pageInsets.left - self.springBoard.pageInsets.right*/);
}


- (NSUInteger)_numberOfPages{
    
    return ceilf((float)((float)self.cellCount / (float)self.cellsPerPage));
    
}

- (CGSize)_pageSizeWithInsetsApplied{

    return self.springBoardBounds.size;
    //return UIEdgeInsetsInsetRect(self.springBoardBounds, self.springBoard.pageInsets).size;
}


- (CGSize)_contentSize{
    
    CGFloat pageHeight = self.pageSize.height;
    CGFloat width = self.pageCount * self.pageSize.width;
    
    return CGSizeMake(width, pageHeight);
}

- (NSUInteger)_pageForCellAtPosition:(CellPosition)position{
    
    NSUInteger index = position.index;
    
    if(index == 0)
        return 0;
    
    float p = (float)((float)(index) / (float)self.cellsPerPage);
    
    p = floorf(p);
    
    NSUInteger page = (NSUInteger)p;
    
    return page;
}


- (CellPagePosition)_cellPagePositionForCellPosition:(CellPosition)position{
    
    CellPagePosition p;
    p.index = position.index;
    p.column = position.column;
    p.page = [self _pageForCellAtPosition:position];
    
    NSUInteger numberOfRowsBeforePage = self.rowsPerPage * (p.page);
    p.row = position.row - numberOfRowsBeforePage;
    
    return p;
}



- (CGPoint)_originForCellAtPosition:(CellPosition)position{
    
    
    CellPagePosition pagePosition = [self _cellPagePositionForCellPosition:position];;
    
    float widthOfPagesBeforePage = pagePosition.page * self.pageSize.width;

    float widthOfCellsInRowBeforeCell = self.cellSize.width * pagePosition.column;
    
    float widthOfSpacesInRowBeforeCell = self.horizontalCellSpacing * (pagePosition.column + 1);

    float widthInRowBeforeCell = widthOfCellsInRowBeforeCell + widthOfSpacesInRowBeforeCell;
            
    CGFloat x = widthOfPagesBeforePage + widthInRowBeforeCell;
    
    if(x < 0 || x == NAN){
        ALWAYS_ASSERT;
    }
    
    float heightOfCellsInColumnBeforeCell = self.cellSize.height * pagePosition.row;
    
    float heightOfSpacesInColumnBeforeCell = self.veritcalCellSpacing * (pagePosition.row + 1);
    
    float heighInColumnBeforeCell = heightOfCellsInColumnBeforeCell + heightOfSpacesInColumnBeforeCell;

    CGFloat y = heighInColumnBeforeCell; 
    
    if(y < 0 || y == NAN){
        ALWAYS_ASSERT;
    }   
    
    CGPoint origin;
    origin.x = x;
    origin.y = y;
    
    return origin;
}

- (NSUInteger)pageForContentOffset:(CGPoint)offset{
        
    float pageWidth = self.pageSize.width;
    
    float offsetX = offset.x;
    
    float val = offsetX/pageWidth;

    val = roundf(val);
    
    if(val < 0){     
        val = 0;
    }
    
    NSUInteger page = (NSUInteger)val;
    
    if(page >= self.pageCount && page > 0){
        
        page = self.pageCount-1;
    }
    
    return page;
    
}


- (CGRect)frameForPage:(NSUInteger)page{
    
    if(page >= self.pageCount)
        return CGRectZero;

    CGRect f = CGRectZero;
    f.size = self.pageSize;
    f.origin =  [self offsetForPage:page];
    
    return f;
    
}

- (CGPoint)offsetForPage:(NSUInteger)page{
    
    if(page >= self.pageCount)
        return CGPointZero;

    return CGPointMake([self _horizontalOffsetForPage:page], 0);
}

- (CGFloat)_horizontalOffsetForPage:(NSUInteger)page{
    
    return springBoardBounds.size.width * (float)page;
    
}

- (NSUInteger)pageForCellIndex:(NSUInteger)index{
    
    CellPosition pos = [self _positionForCellAtIndex:index];
    NSUInteger page = [self _pageForCellAtPosition:pos];
    return page;
}


- (NSIndexSet*)cellIndexesForPage:(NSUInteger)page{
        
    if(page == NSNotFound)
        return nil;
    
    /*
    if(page > 0 && page >= self.pageCount)
        return nil;
    */
    
    NSUInteger numOfCellsOnPage = self.cellsPerPage;

    NSUInteger numberOfCellsBeforePage = 0;
    NSUInteger firstIndex = 0;
    
    if(page > 0){
        numberOfCellsBeforePage = self.cellsPerPage * (page);
        firstIndex += numberOfCellsBeforePage;
    }
    
    /*
    if(firstIndex >= self.cellCount)
        return nil;

    if(page == self.pageCount-1){
        
        numOfCellsOnPage = self.cellCount - numberOfCellsBeforePage;
        
    }
    */
    
    NSRange cellRange = NSMakeRange(firstIndex, numOfCellsOnPage);

    NSIndexSet* cellIndexes = [NSIndexSet indexSetWithIndexesInRange:cellRange];
    
    return cellIndexes;
}

- (NSRange)visibleRangeWithPaddingForContentOffset:(CGPoint)offset{
    
    NSUInteger page = [self pageForContentOffset:offset];
    
    NSUInteger previousPage = page;
    
    if(page > 0)
       previousPage = page-1;
    
    NSUInteger nextPage = page+1;
    
    NSMutableIndexSet* set = [NSMutableIndexSet indexSet];
    [set addIndexes:[self cellIndexesForPage:page]];
    [set addIndexes:[self cellIndexesForPage:previousPage]];
    [set addIndexes:[self cellIndexesForPage:nextPage]];
    
#ifdef DEBUG

    if([set count] > 0)
        ASSERT_TRUE(indexesAreContiguous(set));
    
#endif
    
    NSRange r = rangeWithContiguousIndexes(set);
    
    return r;
}

- (NSRange)visibleRangeForContentOffset:(CGPoint)offset{
    
    NSUInteger page = [self pageForContentOffset:offset];
        
    NSMutableIndexSet* set = [NSMutableIndexSet indexSet];
    [set addIndexes:[self cellIndexesForPage:page]];
    
#ifdef DEBUG
    
    if([set count] > 0)
        ASSERT_TRUE(indexesAreContiguous(set));
    
#endif
    
    NSRange r = rangeWithContiguousIndexes(set);
    
    return r;

    
}





@end
