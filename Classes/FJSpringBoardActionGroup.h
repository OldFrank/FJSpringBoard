//
//  FJSpringBoardActionGroup.h
//  Vimeo
//
//  Created by Corey Floyd on 9/15/11.
//  Copyright 2011 Flying Jalapeño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMModelObject.h"
#import "FJSpringBoardAction.h"

@interface FJSpringBoardActionGroup : SMModelObject{
    
    NSArray* cellStateBeforeAction;
    
    NSMutableSet* reloadActions;
    NSMutableSet* deleteActions;
    NSMutableSet* insertActions;
    
    BOOL locked;
    NSUInteger lockCount;
    
    BOOL validated;
}
@property (nonatomic, retain) NSMutableSet *reloadActions;
@property (nonatomic, retain) NSMutableSet *deleteActions;
@property (nonatomic, retain) NSMutableSet *insertActions;
@property (nonatomic, getter=isLocked, readonly) BOOL locked;
@property (nonatomic, assign) NSUInteger lockCount;
@property (nonatomic, getter=isValidated) BOOL validated;



- (void)addActionWithType:(FJSpringBoardActionType)type indexes:(NSIndexSet*)indexSet animation:(FJSpringBoardCellAnimation)animation; //will auto lock unless autoLock == NO

- (NSIndexSet*)indexesToInsert;
- (NSIndexSet*)indexesToDelete;

- (void)lock;

- (void)beginUpdates;
- (void)endUpdates;

@end
