//
//  AppDelegate.h
//  RechercheHtml
//
//  Created by William MERLE-MARTY on 23/11/2016.
//  Copyright © 2016 William MERLE-MARTY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

