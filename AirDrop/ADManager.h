//
//  ADManager.h
//  Conecta
//
//  Created by Javier Berlana on 19/09/13.
//  Copyright (c) 2013 NSSpainTeam. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MultipeerConnectivity/MultipeerConnectivity.h>

typedef void (^ADPeersChangedBlockType) (NSArray *peers, NSError *error);

@protocol ADManagerDelegate;

@interface ADManager : NSObject

@property (weak) id<ADManagerDelegate> delegate;

/* Look for peers */
- (void)starLookingForPeers:(void (^)(NSArray *peers, NSError *error))peersChage;
- (void)stopLookingForPeers;

/* Disclose peer */
- (void)startAdvertisingPeer;
- (void)stopAdvertisingPeer;

/* Connect */
- (void)connectToPeers:(NSArray *)peerIDs onCompletion:(ADPeersChangedBlockType)complete;

/* Send data */
- (BOOL)sendData:(NSData *)dataToSend toPeers:(NSArray *)peersIds withError:(NSError **)error;
- (BOOL)sendData:(NSData *)dataToSend toPeers:(NSArray *)peersIds withTimeout:(NSUInteger)timeout withError:(NSError **)error;

@end

@protocol ADManagerDelegate <NSObject>

@optional
- (void)manager:(ADManager *)manager didReceiveInvitationFromPeer:(MCPeerID *)peer completionHandler:(void(^)(BOOL accept)) completionHandler;
- (BOOL)manager:(ADManager *)manager didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peer;

@end