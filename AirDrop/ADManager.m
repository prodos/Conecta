//
//  ADManager.m
//  Conecta
//
//  Created by Javier Berlana on 19/09/13.
//  Copyright (c) 2013 NSSpainTeam. All rights reserved.
//

#import "ADManager.h"

@interface ADManager() <MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate> {
    
    ADPeersChangedBlockType _peersChangeBlock;
}

@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCPeerID *myPeerId;
@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;

@property (strong, nonatomic) NSMutableArray *peers;

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
        self.peers = [NSMutableArray array];
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
        if (![self.peers containsObject:peerID]) {
            [self.peers addObject:peerID];
            _peersChangeBlock(_peers, nil);
        }
    }
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"MCNearbyServiceABrowserDelegate :: lostPeer :: PeerID : %@",peerID);
    
    if(peerID != nil)
    {
        if ([self.peers containsObject:peerID]) {
            [self.peers removeObject:peerID];
            _peersChangeBlock(_peers, nil);
        }
    }
    
    //[self.advertiser startAdvertisingPeer];
    //[self.browser invitePeer:peerID toSession:self.session withContext:[@"Airdrop" dataUsingEncoding:NSUTF8StringEncoding] timeout:10];
}


#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSLog(@"MCSessionDelegate :: didReceiveData :: Received %@ from %@",[data description],peerID);

    [self.delegate manager:self
            didReceiveData:data fromPeer:peerID];
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

    if (state == MCSessionStateConnected && self.session) {
        
        NSError *error;
        NSLog(@"MCSessionStateConnected :: didChangeState :: PeerId %@ changed to state %d",peerID,state);
        //[self.session sendData:[[[_txtStatus.text stringByAppendingString:@" And "] stringByAppendingString:_txtAmount.text] dataUsingEncoding:NSUTF8StringEncoding] toPeers:[NSArray arrayWithObject:peerID] withMode:MCSessionSendDataReliable error:&error];
        
    } else if (state == MCSessionStateNotConnected && self.session){
        
        [self.advertiser startAdvertisingPeer];
        
        
        //        [self.session sendData:[_txtStatus.text dataUsingEncoding:NSUTF8StringEncoding] toPeers:[NSArray arrayWithObject:peerID] withMode:MCSessionSendDataReliable error:&error];
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
