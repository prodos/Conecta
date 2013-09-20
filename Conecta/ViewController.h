//
//  ViewController.h
//  Conecta
//
//  Created by Roberto Miranda Gonzalez on 19/09/13.
//  Copyright (c) 2013 NSSpainTeam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *peersTableView;

@property (weak, nonatomic) IBOutlet UIImageView *imageToSend;

@property (weak, nonatomic) IBOutlet UIButton *pickImgBtn;
@property (weak, nonatomic) IBOutlet UIButton *sendImgBtn;

- (IBAction)pickImageTapped:(id)sender;
- (IBAction)sendImageTapped:(id)sender;

@end
