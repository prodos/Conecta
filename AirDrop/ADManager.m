//
//  ADManager.m
//  Conecta
//
//  Created by Javier Berlana on 19/09/13.
//  Copyright (c) 2013 NSSpainTeam. All rights reserved.
//

#import "ADManager.h"

@interface ADManager() <MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate>

@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCPeerID *myPeerId;
@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;

- (instancetype)initWithPeerID:(NSString *)peerID
                 discoveryInfo:(NSDictionary *)discoveryInfo
                   serviceType:(NSString *)serviceType;

@end


@implementation ADManager

static const NSUInteger kDefaultTimeout = 10;

/*



- (void)stopLookingForPeers;
// 1. Browser – stopBrowsingForPeers

- (void)startAdvertisingPeer;
// 1. Advertiser -startAdvertisingPeer

- (void)stopAdvertisingPeer;
// 1. Advertiser -stopAdvertisingPeer

- (void)connectToPeers:(NSArray *)peerIDs onCompletion:(void (^)(id responseObject, NSError *error))complete;
// 1. andar un ainvitación
//    Browser – invitePeer:toSession:withContext:timeout:
// 2. Recibe el cambio de estado
//    Session delegate – session:peer:didChangeState:
// 3. Notifica con el bloque

- (BOOL)sendData:(NSData *)dataToSend toPeers:(NSArray *)peersIds withError:(NSError **)error;

@end

@protocol ADManagerDelegate <NSObject>

- (void)manager:(ADManager *)manager didReceiveInvitationFromPeer:(MCPeerID *)peer completionHandler:(void(^)(BOOL accept)) completionHandler;
- (BOOL)manager:(ADManager *)manager didReceiveData:(NSData *)data;

@end
 
 */

#pragma mark - Initializers

+ (ADManager *)sharedManagerWithPeerID:(NSString *)peerID
                         discoveryInfo:(NSDictionary *)discoveryInfo
                           serviceType:(NSString *)serviceType
{
    static ADManager *_sharedManager = nil;
    static dispatch_once_t airDropToken;
    
    dispatch_once(&airDropToken, ^{
        
        _sharedManager = [[ADManager alloc] initWithPeerID:peerID
                                             discoveryInfo:discoveryInfo
                                               serviceType:serviceType];
    });
    
    return _sharedManager;
}

- (instancetype)initWithPeerID:(NSString *)peerID
                 discoveryInfo:(NSDictionary *)discoveryInfo
                   serviceType:(NSString *)serviceType
{
    self = [super init];
    if (self)
    {
        self.myPeerId = [[MCPeerID alloc] initWithDisplayName:peerID];
        
        // Initialize browser
        self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.myPeerId
                                                        serviceType:serviceType];
        self.browser.delegate = self;
        
        // Initialize session
        self.session = [[MCSession alloc] initWithPeer:self.myPeerId
                                      securityIdentity:nil
                                  encryptionPreference:MCEncryptionRequired];
        self.session.delegate = self;
        
        // Initialize session
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.myPeerId
                                                            discoveryInfo:discoveryInfo
                                                              serviceType:serviceType];
        self.advertiser.delegate = self;
    }
    
    return self;
}


#pragma mark - Public methods

#pragma mark - Look for peers

- (void)starLookingForPeers:(void (^)(NSArray *peers, NSError *error))peersChage
{
    [_browser startBrowsingForPeers];
}
// 1. Browser – startBrowsingForPeers
// 2.1 Browser Delegate – browser:foundPeer:withDiscoveryInfo:
// 2.2 Browser Delegate – browser:lostPeer:

- (void)stopLookingForPeers
{
    [_browser stopBrowsingForPeers];
}


#pragma mark - Disclose peer

- (void)startAdvertisingPeer
{
    [_advertiser startAdvertisingPeer];
}

- (void)stopAdvertisingPeer
{
    [_advertiser stopAdvertisingPeer];
}

#pragma mark - Send data to peers

- (BOOL)sendData:(NSData *)dataToSend
         toPeers:(NSArray *)peersIds
       withError:(NSError *__autoreleasing *)error {
    return [self sendData:dataToSend
                  toPeers:peersIds
              withTimeout:kDefaultTimeout
                withError:error];
}

- (BOOL)sendData:(NSData *)dataToSend
         toPeers:(NSArray *)peersIds
     withTimeout:(NSUInteger)timeout
       withError:(NSError *__autoreleasing *)error {
    return [_session sendData:dataToSend
                      toPeers:peersIds
                     withMode:MCSessionSendDataReliable
                        error:error];
}


@end
