//
//  UserFriendService.h
//  WizardWar
//
//  Created by Sean Hess on 6/21/13.
//  Copyright (c) 2013 The LAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "Wizard.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <Firebase/Firebase.h>

@interface UserService : NSObject

// currentUser ALWAYS exists with at least the userId
@property (nonatomic, strong) User * currentUser;
@property (nonatomic, strong) User * lastUpdatedUser;
@property (nonatomic, readonly) Wizard * currentWizard;

@property (nonatomic) BOOL pushAccepted;
@property (nonatomic, readonly) BOOL isConnected;

+ (UserService *)shared;

- (void)saveDeviceToken:(NSString*)deviceToken;
- (void)saveCurrentUser;
- (void)connect:(Firebase*)root;
- (void)disconnect;

- (void)deleteAllData;

- (BOOL)isAuthenticated;

- (NSString*)randomWizardName;

- (User*)userWithPredicate:(NSPredicate*)predicate;
- (User*)userWithId:(NSString*)userId;
- (User*)userWithId:(NSString*)userId create:(BOOL)create;

- (NSSortDescriptor*)sortIsOnline;
- (NSPredicate*)predicateIsUser:(NSString*)userId;
- (NSPredicate*)predicateIsOnline:(BOOL)online;
- (NSFetchRequest*)requestAllUsers;
- (NSFetchRequest*)requestAllUsersExcept:(User*)user;
- (NSFetchRequest*)requestOtherOnline:(User*)user;

- (BOOL)user:(User*)user shouldUpgradeToMatch:(User*)user;



@end
