//
//  ViewController.m
//  Conecta
//
//  Created by Roberto Miranda Gonzalez on 19/09/13.
//  Copyright (c) 2013 NSSpainTeam. All rights reserved.
//

#import "ViewController.h"
#import "ADManager.h"
#import "NewImageViewController.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, ADManagerDelegate>

@property (nonatomic, strong) NSMutableArray *peers;
@property (nonatomic, strong) NSMutableArray *connectedPeers;

@property (nonatomic, strong) ADManager *myADManager;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.peers          = [NSMutableArray array];
    self.connectedPeers = [NSMutableArray array];
    
    self.sendImgBtn.enabled = NO;
	
    // Initialize the ADManager
    self.myADManager = [[ADManager alloc] initWithPeerID:[[UIDevice currentDevice] name]];
    self.myADManager.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showImageSegue"])
    {
        NewImageViewController *newImageVC = segue.destinationViewController;
        newImageVC.data = sender;
    }
}

#pragma mark - ADManagerDelegate

- (void)manager:(ADManager *)manager didDetectNewPeer:(MCPeerID *)peer
{
    [self.peers addObject:peer];
    [self.peersTableView reloadData];
}

- (void)manager:(ADManager *)manager didLostAPeer:(MCPeerID *)peer
{
    [self.peers removeObject:peer];
    [self.peersTableView reloadData];
}

- (void)manager:(ADManager *)manager didConnectPeer:(MCPeerID *)peerID
{
    [self.connectedPeers addObject:peerID];
    [self.peersTableView reloadData];
}

- (void)manager:(ADManager *)manager didDisconnectPeer:(MCPeerID *)peerID
{
    [self.connectedPeers removeObject:peerID];
    [self.peersTableView reloadData];
}

- (void)manager:(ADManager *)manager didReceiveInvitationFromPeer:(MCPeerID *)peer completionHandler:(void(^)(BOOL accept)) completionHandler
{
    // Allow all invitations
    completionHandler(YES);
}

- (BOOL)manager:(ADManager *)manager didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peer
{
    [self performSegueWithIdentifier:@"showImageSegue" sender:data];
    return YES;
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.peers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PeerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    MCPeerID *peerID = self.peers[indexPath.row];
    cell.textLabel.text = peerID.displayName;
    
    if ([self.connectedPeers containsObject:peerID]) {
        cell.imageView.image = [UIImage imageNamed:@"online-icon"];
    }
    else {
        cell.imageView.image = [UIImage imageNamed:@"offline-icon"];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCPeerID *peerToConnect = self.peers[indexPath.row];
    if (peerToConnect && ![self.connectedPeers containsObject:peerToConnect])
    {
        __weak ViewController *mySelf = self;
        
        [self.myADManager connectToPeers:@[peerToConnect] onCompletion:^(MCPeerID *peer, NSError *error)
        {
            [mySelf.connectedPeers addObject:peer];
            mySelf.sendImgBtn.enabled = self.imageToSend.image != nil;
        }];
    }
}

#pragma mark - Actions

- (IBAction)pickImageTapped:(id)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setAllowsEditing:YES];
    [picker setDelegate:self];
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:^{}];
}

- (IBAction)sendImageTapped:(id)sender
{
    if (self.peers.count > 0 && self.imageToSend.image)
    {
        NSData *imageData = UIImagePNGRepresentation(self.imageToSend.image);
        NSError *error;
        [self.myADManager sendData:imageData toPeers:self.peers withError:&error];
    }
}

#pragma mark - Image picker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    [self dismissViewControllerAnimated:YES completion:^{}];
    [self.imageToSend setImage:image];
    
    self.sendImgBtn.enabled = self.connectedPeers.count > 0;
}

@end
