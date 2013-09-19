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

@property (nonatomic, strong) NSArray *peers;
@property (nonatomic, strong) NSMutableArray *connectedPeers;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Initialize the ADManager
    [[ADManager sharedManager] configureWithPeerID:[[UIDevice currentDevice] name] discoveryInfo:@{} serviceType:@"MyAppName"];
    [[ADManager sharedManager] startAdvertisingPeer];
    [[ADManager sharedManager] starLookingForPeers:^(NSArray *peers, NSError *error)
    {
        if (!error) {
            [self airDropPeersHasChanged:peers];
        }
    }];
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

#pragma mark - AirDrop stuff

- (void)airDropPeersHasChanged:(NSArray *)peers
{
    self.peers = peers;
    [self.peersTableView reloadData];
}

- (void)manager:(ADManager *)manager didReceiveInvitationFromPeer:(MCPeerID *)peer completionHandler:(void(^)(BOOL accept)) completionHandler
{
    
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
    
    cell.textLabel.text = self.peers[indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCPeerID *peerToConnect = self.peers[indexPath.row];
    if (![self.connectedPeers containsObject:peerToConnect])
    {
        [self.connectedPeers addObject:peerToConnect];
        [[ADManager sharedManager] connectToPeers:self.connectedPeers onCompletion:^(NSArray *peers, NSError *error)
        {
            self.connectedPeers = [peers mutableCopy];
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
    NSData *imageData = UIImagePNGRepresentation(self.imageToSend.image);
    NSError *error;
    [[ADManager sharedManager] sendData:imageData toPeers:self.peers withError:&error];
}

#pragma mark - Image picker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    [self dismissViewControllerAnimated:YES completion:^{}];
    [self.imageToSend setImage:image];
}

@end
