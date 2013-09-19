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
typedef void (^ADPeerDidConnectedBlockType) (MCPeerID *peer, NSError *error);

@protocol ADManagerDelegate;

@interface ADManager : NSObject

/* Configuration */
+ (ADManager *)sharedManager;

- (void)configureWithPeerID:(NSString *)peerID
              discoveryInfo:(NSDictionary *)discoveryInfo
                serviceType:(NSString *)serviceType;

@property (weak) id<ADManagerDelegate> delegate;

/* Look for peers */
- (void)starLookingForPeers:(ADPeersChangedBlockType)peersChage;
- (void)stopLookingForPeers;

/* Disclose peer */
- (void)startAdvertisingPeer;
- (void)stopAdvertisingPeer;

/* Connect */
- (void)connectToPeers:(NSArray *)peerIDs onCompletion:(ADPeerDidConnectedBlockType)completion;

/* Send data */
- (BOOL)sendData:(NSData *)dataToSend toPeers:(NSArray *)peersIds withError:(NSError **)error;
- (BOOL)sendData:(NSData *)dataToSend toPeers:(NSArray *)peersIds withTimeout:(NSUInteger)timeout withError:(NSError **)error;

@end

@protocol ADManagerDelegate <NSObject>

@optional
- (void)manager:(ADManager *)manager didReceiveInvitationFromPeer:(MCPeerID *)peer completionHandler:(void(^)(BOOL accept)) completionHandler;
- (BOOL)manager:(ADManager *)manager didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peer;

//- (void)manager:(ADManager*)manager peer:(MCPeerID*)peerID didConnect

/* Error handling */
- (BOOL)manager:(ADManager *)manager didNotStartAdvertisingPeer:(NSError *)error;

@end