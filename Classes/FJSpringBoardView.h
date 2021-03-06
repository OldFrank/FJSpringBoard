

#import <UIKit/UIKit.h>
#import "FJSpringBoardUtilities.h"
#import "FJSpringBoardCell.h"

@class FJReorderingIndexMap;

@class FJSpringBoardIndexLoader;
@class FJSpringBoardLayout;
@class FJSpringBoardUpdate;

@class FJSpringBoardView;

@protocol FJSpringBoardViewDataSource;

typedef enum  {
    FJSpringBoardCellAnimationNone,
    FJSpringBoardCellAnimationFade
} FJSpringBoardCellAnimation;

typedef enum  {
    FJSpringBoardCellScrollPositionTop,
    FJSpringBoardCellScrollPositionMiddle,
    FJSpringBoardCellScrollPositionBottom
} FJSpringBoardCellScrollPosition;

typedef enum  {
    FJSpringBoardViewScrollDirectionVertical,
    FJSpringBoardViewScrollDirectionHorizontal
} FJSpringBoardViewScrollDirection;


@protocol FJSpringBoardViewDelegate <NSObject, UIScrollViewDelegate>

@optional
- (void)springBoardView:(FJSpringBoardView *)springBoardView willSelectCellAtIndex:(NSUInteger)index;
- (void)springBoardView:(FJSpringBoardView *)springBoardView didSelectCellAtIndex:(NSUInteger)index; 
- (void)springBoardView:(FJSpringBoardView *)springBoardView willDeselectCellAtIndex:(NSUInteger)index;
- (void)springBoardView:(FJSpringBoardView *)springBoardView didDeselectCellAtIndex:(NSUInteger)index; 

- (void)springBoardView:(FJSpringBoardView *)springBoardView didUpdateCurrentPage:(NSUInteger)page numberOfPages:(NSUInteger)totalPages;


@end

@protocol FJSpringBoardViewDataSource <NSObject>

- (NSUInteger)numberOfCellsInSpringBoardView:(FJSpringBoardView *)springBoardView;
- (FJSpringBoardCell *)springBoardView:(FJSpringBoardView *)springBoardView cellAtIndex:(NSUInteger )index;


@optional

//simple drag and drop
- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canMoveCellAtIndex:(NSUInteger)index; //you must implement the following method as well
- (void)springBoardView:(FJSpringBoardView *)springBoardView moveCellAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex; //update your model

//deletion
- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canDeleteCellAtIndex:(NSUInteger)index; //you must implement the following method as well
- (void)springBoardView:(FJSpringBoardView *)springBoardView commitDeletionForCellAtIndex:(NSUInteger)index; //update your model

//NOT IMPLEMENTED
//drag and drop ONTO another cell
- (BOOL)springBoardView:(FJSpringBoardView *)springBoardView canDropCellFromIndex:(NSUInteger)formIndex onCellAtIndex:(NSUInteger)dropIndex; 
- (FJSpringBoardCell*)springBoardView:(FJSpringBoardView *)springBoardView willDropCellOntoCell:(FJSpringBoardCell*)dropCell atIndex:(NSUInteger)dropIndex; //chance to customize a cell before another cell is dropped onto it
- (void)springBoardView:(FJSpringBoardView *)springBoardView dropCellAtIndex:(NSUInteger)fromIndex onCellAtIndex:(NSUInteger)toIndex; //update your model. the cell at the drop index will be reloaded after this call



@end

@interface FJSpringBoardView : UIScrollView <UIGestureRecognizerDelegate> {

    UIView* contentView;
    
    UIEdgeInsets pageInsets;
    
    CGSize cellSize;
    
    FJSpringBoardViewScrollDirection scrollDirection;

    FJSpringBoardIndexLoader* indexLoader;
    FJSpringBoardLayout *layout;
      
    NSMutableArray *cells;
    
    FJSpringBoardUpdate *updateInProgress;
    
    NSMutableSet *reusableCells; //reusable cells

    BOOL animateContentsDuringBoundsChange;

    BOOL suspendLayoutUpdates;

    BOOL doubleTapped;
    BOOL longTapped;
    
    BOOL paging;
    
    NSIndexSet* visibleCellsPriorToBoundsChange;

    FJSpringBoardCellAnimation layoutAnimation;
    
    FJSpringBoardCellMode mode;
    
    NSMutableIndexSet *selectedIndexes;

    CGPoint lastTouchPoint;

    UIView* draggableCellView;
        
    NSUInteger indexOfHighlightedCell;
    
    id<FJSpringBoardViewDataSource> dataSource;
    //id<FJSpringBoardViewDelegate> delegate;
        
}
//delegate and datasource like UITableView
@property(nonatomic, assign) IBOutlet id<FJSpringBoardViewDataSource> dataSource;
@property(nonatomic, assign) IBOutlet id<FJSpringBoardViewDelegate> delegate;

@property(nonatomic) CGSize cellSize; //be sure your cells are the size you specify here. careful, you should reload after chenging this or hilarity will ensue.

//smooth vertical scrolling or paginated horizontal
@property(nonatomic) FJSpringBoardViewScrollDirection scrollDirection;

//should the cells be visible when moving as a result of the springboard bounds changing?
@property (nonatomic, assign) BOOL animateContentsDuringBoundsChange; //default = NO

//reload data, like UITableView this only loads visible cells
- (void)reloadData;


//yes, also like a UITableView, sensing a pattern here?
- (FJSpringBoardCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;


//cell info
- (NSUInteger)numberOfCells;
- (FJSpringBoardCell *)cellAtIndex:(NSUInteger)index; //returns nill if out of range or not visible
- (NSUInteger)indexForCell:(FJSpringBoardCell *)cell;
- (CGRect)frameForCellAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfCellAtPoint:(CGPoint)point;

@property(nonatomic, retain, readonly) NSIndexSet *visibleCellIndexes; 
@property(nonatomic, retain, readonly) NSArray *visibleCells; 

//scroll, note: position is ignored in horizontal scroll direction
- (void)scrollToCellAtIndex:(NSUInteger)index atScrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition animated:(BOOL)animated;


//editing behavior
@property(nonatomic) BOOL beginEditingOnTapAndHold; //default = YES


//selection
@property(nonatomic) BOOL allowsMultipleSelection; //default  = NO

- (void)selectCellAtIndex:(NSUInteger)index animated:(BOOL)animated scrollPosition:(FJSpringBoardCellScrollPosition)scrollPosition;
- (void)deselectCellAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)deselectCellsAtIndexes:(NSIndexSet*)indexes animated:(BOOL)animated;

- (NSUInteger)selectedCellIndex;
- (NSIndexSet*)selectedCellIndexes;


//the following methods are used to animate changes without a full reload
- (void)reloadCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;
- (void)insertCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;
- (void)deleteCellsAtIndexes:(NSIndexSet *)indexSet withCellAnimation:(FJSpringBoardCellAnimation)animation;

//use these to perform multiple updates at once
- (void)beginUpdates; //nestable
- (void)endUpdates;



//mode
@property(nonatomic) FJSpringBoardCellMode mode; //KVO to be notified about mode changes


//Selection, these only work in Selection Mode
/*
- (void)selectCellAtIndex:(NSUInteger)index;
- (void)selectCellsAtIndexes:(NSIndexSet*)indexSet;

- (void)deselectCellAtIndex:(NSUInteger)index;
- (void)deselectCellsAtIndexes:(NSIndexSet*)indexSet;
*/

- (NSIndexSet *)indexesForSelectedCells;



//paging, only valid if scrollingDirection == horizontal

//these are in addition to the normal scroll view content insets
@property(nonatomic) UIEdgeInsets pageInsets; //not implemented

- (NSUInteger)numberOfPages;
- (NSUInteger)currentPage;

- (BOOL)scrollToPage:(NSUInteger)page animated:(BOOL)animated;


@end


