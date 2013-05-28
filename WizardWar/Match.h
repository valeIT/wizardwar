//
//  Match.h
//  WizardWar
//
//  Created by Sean Hess on 5/17/13.
//  Copyright (c) 2013 The LAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Spell.h"
#import "Player.h"

#define TICK_INTERVAL 0.1

typedef enum MatchStatus {
    MatchStatusReady,
    MatchStatusPlaying,
    MatchStatusEnded,
} MatchStatus;

#define MATCH_STATE_KEYPATH @"status"

@protocol MatchDelegate
-(void)didAddSpell:(Spell*)spell;
-(void)didRemoveSpell:(Spell*)spell;

-(void)didAddPlayer:(Player*)player;
-(void)didRemovePlayer:(Player*)player;

-(void)didTick:(NSInteger)currentTick;
@end

@interface Match : NSObject
@property (nonatomic, strong) NSMutableDictionary * players;
@property (nonatomic, strong) NSMutableDictionary * spells;
@property (nonatomic, weak) id<MatchDelegate> delegate;
@property (nonatomic, strong) Player * currentPlayer;
@property (nonatomic, strong) Player * opponentPlayer;

@property (nonatomic, readonly) NSArray * sortedPlayers;

@property (nonatomic) MatchStatus status;

-(id)initWithId:(NSString*)id currentPlayer:(Player*)player withAI:(Player*)ai;
-(void)update:(NSTimeInterval)dt;
-(void)castSpell:(Spell *)spell;
-(void)disconnect;
@end
