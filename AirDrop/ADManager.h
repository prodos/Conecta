//
//  ADManager.h
//  Conecta
//
//  Created by Javier Berlana on 19/09/13.
//  Copyright (c) 2013 NSSpainTeam. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MultipeerConnectivity/MultipeerConnectivity.h>

@protocol ADManagerDelegate;

@interface ADManager : NSObject

/* Look for peers */
- (void)starLookingForPeers:(void (^)(NSArray *peers, NSError *error))peersChage;
// 1. Browser – startBrowsingForPeers
// 2.1 Browser Delegate – browser:foundPeer:withDiscoveryInfo:
// 2.2 Browser Delegate – browser:lostPeer:

- (void)stopLookingForPeers;
// 1. Browser – stopBrowsingForPeers


/* Disclosure peer */
- (void)startAdvertisingPeer;
// 1. Advertiser -startAdvertisingPeer

- (void)stopAdvertisingPeer;
// 1. Advertiser -stopAdvertisingPeer

/* Connect */
- (void)connectToPeers:(NSArray *)peerIDs onCompletion:(void (^)(id responseObject, NSError *error))complete;
// 1. andar un ainvitación
//    Browser – invitePeer:toSession:withContext:timeout:
// 2. Recibe el cambio de estado
//    Session delegate – session:peer:didChangeState:
// 3. Notifica con el bloque

/* Send data */
- (BOOL)sendData:(NSData *)dataToSend toPeers:(NSArray *)peersIds withError:(NSError **)error;



@end

@protocol ADManagerDelegate <NSObject>

- (BOOL) manager:(ADManager*)manager shouldAcceptConnectionInvitationFromPeer:(MCPeerID*)peer;

@end