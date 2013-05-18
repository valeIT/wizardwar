//
//  Match.m
//  WizardWar
//
//  Created by Sean Hess on 5/17/13.
//  Copyright (c) 2013 The LAB. All rights reserved.
//

#import "Match.h"
#import "Spell.h"
#import "Player.h"
#import <Firebase/Firebase.h>
#import "NSArray+Functional.h"

@interface Match ()
@property (nonatomic, strong) Firebase * matchNode;
@property (nonatomic, strong) Firebase * spellsNode;
@property (nonatomic, strong) Firebase * playersNode;
@end

// don't really know which player you are until there are 2 players
// then you can go off their name.
// Alphabetical order baby :)

@implementation Match
-(id)initWithId:(NSString *)id currentPlayer:(Player *)player {
    if ((self = [super init])) {
        self.players = [NSMutableArray array];
        self.spells = [NSMutableArray array];
        
        self.started = NO;
        
        // Firebase
        self.matchNode = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"https://wizardwar.firebaseio.com/match/%@", id]];
        self.spellsNode = [self.matchNode childByAppendingPath:@"spells"];
        self.playersNode = [self.matchNode childByAppendingPath:@"players"];
        
        
        // PLAYERS
        [self.playersNode observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
            Player * player = [Player new];
            [player setValuesForKeysWithDictionary:snapshot.value];
            [self.players addObject:player];
            
            if ([player.name isEqualToString:self.currentPlayer.name]) {
                self.currentPlayer = player;
            }
            
            [self checkStart];
        }];
        
        self.currentPlayer = player;
        
        // FAKE SECOND PLAYER
//        Player * fakeSecondPlayer = [Player new];
//        fakeSecondPlayer.name = @"ZFakeSecondPlayer";
//        [self joinPlayer:fakeSecondPlayer];
        
        [self joinPlayer:self.currentPlayer];
        
        
        // SPELLS
        [self.spellsNode observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
            Spell * spell = [Spell fromType:snapshot.value[@"type"]];
            spell.firebaseName = snapshot.name;
            [spell setValuesForKeysWithDictionary:snapshot.value];
            [self.spells addObject:spell];
            [self.delegate didAddSpell:spell];
        }];
    }
    return self;
}


/// UPDATES

-(void)update:(NSTimeInterval)dt {
    [self.spells forEach:^(Spell*spell) {
        [spell update:dt];
    }];
    
    [self.players forEach:^(Player*player) {
        [player update:dt];
    }];
    
    [self checkHits];
}

-(void)checkHits {
    for (Spell * spell in self.spells) {
        // spells are center anchored, so just check the position, not the width?
        // TODO add spell size to the equation
        // check to see if the spell hits ME, not all players
        // or check to see how my spells hit?
        for (Player * player in self.players)  {
            if ([spell hitsPlayer:player])
                [self hitPlayer:player withSpell:spell];
        }
        
        for (Spell * spell2 in self.spells) {
            if (spell != spell2 && [spell hitsSpell:spell2])
                [self hitSpell:spell withSpell:spell2];
        }
    }
}

-(void)hitPlayer:(Player*)player withSpell:(Spell*)spell {
    NSLog(@"HIT PLAYER %@ with %@", player, spell);
    [self removeSpell:spell];
    
    // this allows it to subtract health
    [spell interactPlayer:player];
    [player.delegate didUpdateForRender];
    [self checkWin];
}

-(void)hitSpell:(Spell*)spell withSpell:(Spell*)spell2 {
    NSLog(@"HIT SPELL %@ with %@", spell, spell2);
    [self handleInteraction:[spell interactSpell:spell2] forSpell:spell];
    [self handleInteraction:[spell2 interactSpell:spell] forSpell:spell2];
}

-(void)checkWin {
    [self.players forEach:^(Player* player) {
        if (player.health == 0) {
            [player setState:PlayerStateDead animated:NO];
            self.started = NO;
            self.loser = player;
            NSLog(@"GAME OVER!");
            [self.delegate matchEnded];
        }
    }];
}

-(void)handleInteraction:(SpellInteraction*)interaction forSpell:(Spell*)spell {
    if (interaction.type == SpellInteractionTypeCancel) {
        [self removeSpell:spell];
    }
    
    else if (interaction.type == SpellInteractionTypeCreate) {
        [self addSpell:interaction.createdSpell];
    }
    
    else if (interaction.type == SpellInteractionTypeModify) {
        Firebase * node = [self.spellsNode childByAppendingPath:spell.firebaseName];
        [node setValue:spell.toObject];
    }
    
    else if (interaction.type == SpellInteractionTypeNothing) {
        // do nothing
    }
    
    else {
        NSAssert(false, @"Did not understand spell interaction type");
    }
    
}

// STARTING

-(void)checkStart {
    NSLog(@"check Start %@", self.players);
    if (self.players.count >= 2) {
        [self start];
    }
}

-(void)start {
    self.started = YES;
    
    // sort alphabetically
    [self.players sortUsingComparator:^NSComparisonResult(Player * p1, Player *p2) {
        return [p1.name compare:p2.name];
    }];
    
    [self.players[0] setPosition:UNITS_MIN];
    [self.players[1] setPosition:UNITS_MAX];
    NSLog(@"START %@", self.players);
    [self.delegate matchStarted];
}


/// ADDING STUFF

-(void)joinPlayer:(Player*)player {
    // [self.players addObject:player];
    Firebase * node = [self.playersNode childByAppendingPath:player.name];
    [node onDisconnectRemoveValue];
    [node setValue:[player toObject]];
}

-(void)addSpell:(Spell*)spell {
//    [self.spells addObject:spell];
    Firebase * spellNode = [self.spellsNode childByAutoId];
//    [spellNode onDisconnectRemoveValue];
    [spellNode setValue:[spell toObject]];
    [spellNode onDisconnectRemoveValue];
    spell.firebaseName = spellNode.name;
}

-(void)removeSpell:(Spell*)spell {
    NSLog(@"REMOVE SPELL %@", spell.firebaseName);
    NSAssert(spell.firebaseName, @"No firebase name on spell! %@", spell);
    Firebase * spellNode = [self.spellsNode childByAppendingPath:spell.firebaseName];
    [self.delegate didRemoveSpell:spell];
    [spellNode removeValue];
    
    // we need to remove this later, since we are enumerating it
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.spells removeObject:spell];
    });
}

-(void)castSpell:(Spell *)spell {
    [spell setPositionFromPlayer:self.currentPlayer];
    [self addSpell:spell]; // add spell
    [self.currentPlayer setState:PlayerStateCast animated:YES];
}

@end
