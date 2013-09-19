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

@end


@implementation ADManager

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

- (id)initWithPeerID:(NSString *)peerID
       discoveryInfo:(NSDictionary *)discoveryInfo
         serviceType:(NSString *)serviceType
{
    
    if (self = [super init])
    {
        self.myPeerId = [[MCPeerID alloc] initWithDisplayName:peerID];
        
        
        NSString *serviceType=@"p2ptest";
        
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


#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"MCNearbyServiceAdvertiserDelegate :: didNotStartAdvertisingPeer :: %@",error);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler
{
    NSLog(@"MCNearbyServiceAdvertiserDelegate :: didReceiveInvitationFromPeer :: peerId :: %@",peerID);
    invitationHandler(TRUE,self.session);
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"MCNearbyServiceABrowserDelegate :: didNotStartBrowsingForPeers :: error :: %@",error);
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"MCNearbyServiceABrowserDelegate :: foundPeer :: PeerID : %@ :: DiscoveryInfo : %@",peerID,info.description);
    
    /*
    if(peerID != nil)
    {
        for (int i=0; i<[peersFound count]; i++)
        {
            if ([[peersFound objectAtIndex:i] isEqualToString:peerID.displayName]) {
                flag=TRUE;
            }
        }
        if (flag==FALSE) {
            [peersFound addObject:peerID.displayName];
            [peersIDs addObject:peerID];
            [_tblPeers reloadData];
            NSLog(@"MCNearbyServiceABrowserDelegate :: foundPeer :: PeerID : %@ ",peersFound.description);
            
            
        }
    }
     */
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    
    NSLog(@"MCNearbyServiceABrowserDelegate :: lostPeer :: PeerID : %@",peerID);
    NSLog(@"ViewController :: launch (Starting Advertise)");
    
    [self.advertiser startAdvertisingPeer];
    //[self.browser invitePeer:peerID toSession:self.session withContext:[@"Airdrop" dataUsingEncoding:NSUTF8StringEncoding] timeout:10];
}

@end
