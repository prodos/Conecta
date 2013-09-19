//
//  Peer.m
//  Conecta
//
//  Created by Alberto Garcia on 19/09/13.
//  Copyright (c) 2013 NSSpainTeam. All rights reserved.
//

#import "Peer.h"

@implementation Peer


-(id)initWithPeer:(MCPeerID *)peer andName:(NSString *)peerName andDiscoveryInfo:(NSDictionary *)discoveryInfo
{
    if ((self = [super init]))
    {
        self.peer = peer;
        self.peerName = peerName;
        self.state = ADStateNotConnected;
        self.discoveryInfo = [NSDictionary dictionaryWithDictionary:discoveryInfo];
    }
    return self;
}
@end
