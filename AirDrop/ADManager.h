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
typedef void (^ADPeerDidConnectBlockType) (MCPeerID *peer, NSError *error);

@protocol ADManagerDelegate;

@interface ADManager : NSObject

@property (weak) id<ADManagerDelegate> delegate;

/* Configuration */
+ (ADManager *)managerWithPeerID:(NSString*)peerID;

/* Search for peers */
// 1. Busco peers (con un ServiceType)
- (void)startLookingForPeersWithServiceType:(NSString*)serviceType;
- (void)stopLookingForPeers;

/* Connect */
// 2. Me conecto con un peer (con un PeerID y en un Contexto)
- (void)connectToPeer:(MCPeerID *)peerID withContext:(NSString*)context withTimeout:(NSUInteger)timeout;

/* Allow being found as peer */
// 3. Me ofrezco como peer (con un ServiceType y un discoveryInfo) -- Con Delegate para aceptar invitaciones a conexión
- (void)startAdvertisingPeerWithServiceType:(NSString*)serviceType andDiscoveryInfo:(NSDictionary*)discoveryInfo;
- (void)stopAdvertisingPeer;

// 3.0 Ha habido un error al inicializar el servicio de activación como peer (delegate con error)
// 3.1 Un peer me ha enviado una invitación, debo aceptarla o rechazarla (con un PeerID, con un contexto, devolver SI o NO)


/* Send/Receive data */
// 4. Envío datos a un peer que está conectado (con un PeerID y con Datos)
- (BOOL)sendData:(NSData *)data toPeer:(MCPeerID *)peersID withError:(NSError **)error;
- (BOOL)sendData:(NSData *)data toPeer:(MCPeerID *)peersID withTimeout:(NSUInteger)timeout withError:(NSError **)error;

// TODO: 4.1 Abro un data stream con el peer (con un PeerID y un DataStream)

// 4.0 Ha habido un fallo al enviar datos (no se han podido enviar todos los datos)
// 4.1 He recibido una conexión con datos de un peer (delegate con peer)
// 4.2 He recibido datos de un peer (delegate con datos y peer y progreso)
// 4.3 He finalizado la recepción de datos de un peer (peer)

@end

@protocol ADManagerDelegate <NSObject>

@optional
// 1.0 There was an error initializing the search-peers service (Delegate with error)
- (void)manager:(ADManager *)manager didFailSearchingPeers:(NSError*)error;

// 1.1 He encontrado a un nuevo peer (con un PeerID y con un discoveryInfo)
- (void)manager:(ADManager *)manager didFindNewPeer:(MCPeerID*)peerID withDiscoveryInfo:(NSDictionary*)discoveryInfo;

// 1.2 He perdido a un peer (con un PeerID)
- (void)manager:(ADManager *)manager didLoosePeer:(MCPeerID*)peerID withDiscoveryInfo:(NSDictionary*)discoveryInfo;

// 2.0 Fallo al conectarse con un peer (E.g: La conexión falló por tiempo de espera, ...)
- (void)manager:(ADManager *)manager didFailConnectingToPeer:(MCPeerID *)peer completionHandler:(void(^)(BOOL accept)) completionHandler;

// 2.1 El peer acepta/rechaza la conexión (delegate peer:Peer statusDidChange:Status)
- (void)manager:(ADManager *)manager didReceiveInvitationFromPeer:(MCPeerID *)peer completionHandler:(void(^)(BOOL accept)) completionHandler;

- (BOOL)manager:(ADManager *)manager didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peer;

//- (void)manager:(ADManager*)manager peer:(MCPeerID*)peerID didConnect

/* Error handling */
- (BOOL)manager:(ADManager *)manager didNotStartAdvertisingPeer:(NSError *)error;

@end