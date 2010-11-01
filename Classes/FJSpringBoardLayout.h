//
//  FJSpringBoardLayout.h
//  FJSpringBoardDemo
//
//  Created by Corey Floyd on 10/28/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FJSpringBoardLayout : NSObject {

    CGRect springBoardbounds;
    CGSize cellSize;

    UIEdgeInsets insets;

    CGFloat horizontalCellSpacing;
    CGFloat verticalCellSpacing;

    BOOL centerCellsInView;
    
    NSUInteger cellCount;
    
    NSUInteger cellsPerRow;
    CGFloat minimumRowWidth;
    CGFloat maximumRowWidth;
    NSUInteger numberOfRows;
    
       
}
//set these properties to calculate layout
@property(nonatomic) UIEdgeInsets insets; //default = 0,0,0,0
@property(nonatomic) CGRect springBoardbounds;

@property(nonatomic) CGSize cellSize;

@property(nonatomic) CGFloat horizontalCellSpacing; //default = 0
@property(nonatomic) CGFloat verticalCellSpacing; //defult = 0

@property(nonatomic) BOOL centerCellsInView; //default = YES

@property(nonatomic) NSUInteger cellCount;

//reset all properties
- (void)reset;

- (void)updateLayout;

- (CGRect)frameForCellAtIndex:(NSUInteger)index;

@property(nonatomic, readonly) CGSize contentSize;




@end
