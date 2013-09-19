//
//  Peer.h
//  Conecta
//
//  Created by Alberto Garcia on 19/09/13.
//  Copyright (c) 2013 NSSpainTeam. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MultipeerConnectivity/MultipeerConnectivity.h>

typedef NS_ENUM(NSInteger, ADState) {
    ADStateNotConnected,     // not in the session
    ADStateConnecting,       // connecting to this peer
    ADStateConnected         // connected to the session
} NS_ENUM_AVAILABLE_IOS(7_0);


@interface Peer : NSObject

@property (nonatomic, strong) NSString *peerName;
@property (nonatomic, strong) MCPeerID *peer;
@property ADState state;
@property (nonatomic, strong) NSDictionary *discoveryInfo;

-(id)initWithPeer:(MCPeerID *)peer andName:(NSString *)peerName andDiscoveryInfo:(NSDictionary *)discoveryInfo;

@end
