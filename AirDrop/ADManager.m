//
//  ADManager.m
//  Conecta
//
//  Created by Javier Berlana on 19/09/13.
//  Copyright (c) 2013 NSSpainTeam. All rights reserved.
//

#import "ADManager.h"
#import "Peer.h"

#define kDEFAULT_DISCOVERY_INFO @{@"BAR":@"FOO",@"BAR2":@"FOO"}
#define kDEFAULT_SERVICE_TYPE @"ServiceType"

@interface ADManager() <MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate> {
    
    ADPeerDidConnectedBlockType _peerDidConnectBlock;
}

@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;

@property (strong, nonatomic) MCPeerID *myPeerId;
@property (strong, nonatomic) NSDictionary *discoveryInfo;
@property (strong, nonatomic) NSString *serviceType;

@property (strong, nonatomic) NSMutableDictionary *peers;

@end

@implementation ADManager

static const NSUInteger kDefaultTimeout = 10;


#pragma mark - Initializers

- (instancetype)initWithPeerID:(NSString *)peerID
{
    return [self initWithPeerID:peerID discoveryInfo:kDEFAULT_DISCOVERY_INFO serviceType:kDEFAULT_SERVICE_TYPE];
}


/* Designated initializer */
- (instancetype)initWithPeerID:(NSString *)peerID
                 discoveryInfo:(NSDictionary *)discoveryInfo
                   serviceType:(NSString *)serviceType
{
    if (self = [super init])
    {
        self.peers    = [NSMutableDictionary dictionary];
        self.myPeerId = [[MCPeerID alloc] initWithDisplayName:peerID];
        
        self.serviceType   = serviceType;
        self.discoveryInfo = discoveryInfo;
        
        // Initialize session
        self.session = [[MCSession alloc] initWithPeer:self.myPeerId
                                      securityIdentity:nil
                                  encryptionPreference:MCEncryptionRequired];
        self.session.delegate = self;
        
        [self startAdvertisingPeer];
        [self starLookingForPeers];
    }
    
    return self;
}

#pragma mark - Public methods

#pragma mark - Look for peers

- (void)starLookingForPeers
{
    if (!_browser)
    {
        // Initialize browser
        self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:_myPeerId serviceType:_serviceType];
        self.browser.delegate = self;
    }
    
    [_browser startBrowsingForPeers];
}

- (void)stopLookingForPeers
{
    [_browser stopBrowsingForPeers];
}


#pragma mark - Disclose peer

- (void)startAdvertisingPeer
{
    if (!_advertiser)
    {
        // Initialize advertiser
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.myPeerId discoveryInfo:_discoveryInfo serviceType:_serviceType];
        self.advertiser.delegate = self;
    }
    
    [_advertiser startAdvertisingPeer];
}

- (void)stopAdvertisingPeer
{
    [_advertiser stopAdvertisingPeer];
}

#pragma mark - Send data to peers

- (BOOL)sendData:(NSData *)dataToSend
         toPeers:(NSArray *)peersIds
       withError:(NSError *__autoreleasing *)error
{
    return [self sendData:dataToSend
                  toPeers:peersIds
              withTimeout:kDefaultTimeout
                withError:error];
}

- (BOOL)sendData:(NSData *)dataToSend
         toPeers:(NSArray *)peersIds
     withTimeout:(NSUInteger)timeout
       withError:(NSError *__autoreleasing *)error
{
    return [_session sendData:dataToSend
                      toPeers:peersIds
                     withMode:MCSessionSendDataReliable
                        error:error];
}

- (void)connectToPeers:(NSArray *)peerIDs onCompletion:(ADPeerDidConnectedBlockType)completion
{
    _peerDidConnectBlock = completion;
    for (MCPeerID *peerID in peerIDs)
    {
        [self.browser invitePeer:peerID
                       toSession:self.session
                     withContext:[@"Airdrop" dataUsingEncoding:NSUTF8StringEncoding]
                         timeout:kDefaultTimeout];
    }
    
    [self.advertiser startAdvertisingPeer];
}


#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"[AD Advertiser] Can not star advertising: %@",error.localizedDescription);
    if ([self.delegate respondsToSelector:@selector(manager:didNotStartAdvertisingPeer:)]) {
        [self.delegate manager:self didNotStartAdvertisingPeer:error];
    }
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler
{
    NSLog(@"[AD Advertiser] Invitation received from: %@",peerID.displayName);
    if ([self.delegate respondsToSelector:@selector(manager:didReceiveInvitationFromPeer:completionHandler:)])
    {
        [self.delegate manager:self didReceiveInvitationFromPeer:peerID completionHandler:^(BOOL accept) {
            double delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_queue_create("invitation_handler_queue", NULL), ^(void){
                invitationHandler(YES, _session);
            });
        }];
    }
}


#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"[AD Browser] Can not star browsing: %@",error.localizedDescription);
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"[AD Browser] New peer found: %@",peerID.displayName);
    
    if(peerID && [self.peers objectForKey:peerID.displayName] == nil)
    {
        Peer *peer = [[Peer alloc] initWithPeer:peerID andName:peerID.displayName andDiscoveryInfo:info];
        [self.peers setObject:peer forKey:peerID.displayName];
        
        if ([self.delegate respondsToSelector:@selector(manager:didDetectNewPeer:)]) {
            [self.delegate manager:self didDetectNewPeer:peerID];
        }
    }
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"[AD Browser] Peer lost: %@",peerID);
    
    if(peerID && [self.peers objectForKey:peerID.displayName])
    {
        [self.peers removeObjectForKey:peerID.displayName];
        
        if ([self.delegate respondsToSelector:@selector(manager:didLostAPeer:)]) {
            [self.delegate manager:self didLostAPeer:peerID];
        }
    }
}


#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSLog(@"MCSessionDelegate :: didReceiveData :: Received %@ from %@",[data description],peerID);

    [self.delegate manager:self didReceiveData:data fromPeer:peerID];
}

- (void)session:(MCSession *)session didReceiveResourceAtURL:(NSURL *)resourceURL fromPeer:(MCPeerID *)peerID
{
    NSLog(@"MCSessionDelegate :: didReceiveResourceAtURL :: Received Resource %@ from %@",[resourceURL description],peerID);
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"MCSessionDelegate :: didReceiveStream :: Received Stream %@ from %@",[stream description],peerID);
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"[AD Session] Peer change state: [%d]%@", state, peerID.displayName);
    Peer *peer = [_peers objectForKey:peerID.displayName];
    
    switch (state)
    {
        case MCSessionStateNotConnected:
            peer.state = ADStateNotConnected;
            [self startAdvertisingPeer];
            
            if ([self.delegate respondsToSelector:@selector(manager:didDisconnectPeer:)]) {
                [self.delegate manager:self didDisconnectPeer:peerID];
            }
            break;
            
        case MCSessionStateConnecting:
            peer.state = ADStateConnecting;
            break;
            
        case MCSessionStateConnected:
            peer.state = ADStateConnected;
            
            if ([self.delegate respondsToSelector:@selector(manager:didConnectPeer:)]) {
                [self.delegate manager:self didConnectPeer:peerID];
            }
            
            break;
    }
}

- (BOOL)session:(MCSession *)session shouldAcceptCertificate:(SecCertificateRef)peerCert forPeer:(MCPeerID *)peerID {
    
    NSLog(@"MCSessionDelegate :: shouldAcceptCertificate from peerID :: %@",peerID);
    return YES;
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    NSLog(@"MCSessionDelegate :: didFinishReceivingResourceWithName :: %@ from peerID :: %@ with error :: %@", resourceName, peerID, error);
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    NSLog(@"MCSessionDelegate :: didStartReceivingResourceWithName :: %@ from peerID :: %@ withProgress :: %@", resourceName, peerID, progress);
}

@end
