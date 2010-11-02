//
//  FJGridViewViewController.h
//  FJGridView
//
//  Created by Corey Floyd on 10/21/10.
//  Copyright 2010 Flying Jalapeño. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FJSpringBoardView.h"

@interface FJSpringBoardDemoViewController : UIViewController <FJSpringBoardViewDelegate, FJSpringBoardViewDataSource> {

    FJSpringBoardView* springBoardView;
    NSUInteger count;
}
@property (nonatomic, retain) FJSpringBoardView *springBoardView;
@property(nonatomic) NSUInteger count;

- (IBAction)insert;

@end

