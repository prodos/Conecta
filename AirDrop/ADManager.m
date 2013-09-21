//
//  ADManager.m
//  Conecta
//
//  Created by Javier Berlana on 19/09/13.
//  Copyright (c) 2013 NSSpainTeam. All rights reserved.
//

#import "ADManager.h"
#import "Peer.h"

@interface ADManager() <MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate> {
    
    ADPeersChangedBlockType _peersChangeBlock;
    ADPeerDidConnectBlockType _peerDidConnectBlock;
}

@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCPeerID *myPeerId;
@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;

@property (strong, nonatomic) NSMutableDictionary *peers;

@end


@implementation ADManager

static const NSUInteger kDefaultTimeout = 10;


#pragma mark - Initializers

+ (ADManager *)sharedManager
{
    static ADManager *_sharedManager = nil;
    static dispatch_once_t airDropToken;
    
    dispatch_once(&airDropToken, ^{
        _sharedManager = [[ADManager alloc] init];
        //[_sharedManager configureWithPeerID:@"DefaultValue" discoveryInfo:@{@"FOO":@"--"} serviceType:@"P2PTest"];
    });
    
    return _sharedManager;
}

- (void)configureWithPeerID:(NSString *)peerID
              discoveryInfo:(NSDictionary *)discoveryInfo
                serviceType:(NSString *)serviceType
{
    self.peers = [NSMutableDictionary dictionary];
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


#pragma mark - Public methods

#pragma mark - Look for peers

- (void)starLookingForPeers:(void (^)(NSArray *, NSError *))peersChage
{
    _peersChangeBlock = peersChage;
    [_browser startBrowsingForPeers];
}

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

- (void)connectToPeers:(NSArray *)peerIDs onCompletion:(ADPeerDidConnectBlockType)completion
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
    NSLog(@"MCNearbyServiceAdvertiserDelegate :: didNotStartAdvertisingPeer :: %@",error);
    if ([self.delegate respondsToSelector:@selector(manager:didNotStartAdvertisingPeer:)]) {
        [self.delegate manager:self didNotStartAdvertisingPeer:error];
    }
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler
{
    NSLog(@"MCNearbyServiceAdvertiserDelegate :: didReceiveInvitationFromPeer :: peerId :: %@",peerID);

    if ([self.delegate respondsToSelector:@selector(manager:didReceiveInvitationFromPeer:completionHandler:)]) {

        [self.delegate manager:self
  didReceiveInvitationFromPeer:peerID
             completionHandler:^(BOOL accept) {
                 invitationHandler(accept, self.session);
             }];
    }
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"MCNearbyServiceABrowserDelegate :: didNotStartBrowsingForPeers :: error :: %@",error);
    
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"MCNearbyServiceABrowserDelegate :: foundPeer :: PeerID : %@ :: DiscoveryInfo : %@",peerID,info.description);
    
    if(peerID != nil)
    {
        if ([self.peers objectForKey:peerID] == nil)
        {
            Peer *peer = [[Peer alloc] initWithPeer:peerID andName:peerID.displayName andDiscoveryInfo:info];
            
            [self.peers setObject:peer forKey:peerID.displayName];
            _peersChangeBlock([_peers allKeys], nil);
        }
    }
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"MCNearbyServiceABrowserDelegate :: lostPeer :: PeerID : %@",peerID);
    
    if(peerID != nil)
    {
        if ([self.peers objectForKey:peerID])
        {
            [self.peers removeObjectForKey:peerID];
            _peersChangeBlock([_peers allKeys], nil);
        }
    }
    
    //[self.advertiser startAdvertisingPeer];
    //[self.browser invitePeer:peerID toSession:self.session withContext:[@"Airdrop" dataUsingEncoding:NSUTF8StringEncoding] timeout:10];
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
    NSLog(@"MCSessionDelegate :: didChangeState :: PeerId %@ changed to state %d",peerID,state);

    Peer *peer = [_peers objectForKey:peerID];
    if (peer)
    {
        peer.state = state;
        if (state == MCSessionStateConnected)
        {
            // Someone has connected
            _peerDidConnectBlock(peerID, nil);
        }
        else if (state == MCSessionStateNotConnected)
        {
            // Someone has disconnected
        }
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
