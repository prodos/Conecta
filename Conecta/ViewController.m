//
//  ViewController.m
//  Conecta
//
//  Created by Roberto Miranda Gonzalez on 19/09/13.
//  Copyright (c) 2013 NSSpainTeam. All rights reserved.
//

#import "ViewController.h"
#import "ADManager.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSArray *peers;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.peers = @[@"Test user 1", @"Test user 2"];
	
    // Initialize the ADManager
    [[ADManager sharedManager] configureWithPeerID:@"myName" discoveryInfo:@{} serviceType:@"MyAppName"];
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

#pragma mark - AirDrop stuff

- (void)airDropPeersHasChanged:(NSArray *)peers
{
    self.peers = peers;
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

- (IBAction)sendImageTapped:(id)sender {
}

#pragma mark - Image picker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    [self dismissViewControllerAnimated:YES completion:^{}];
    [self.imageToSend setImage:image];
}

@end
