//
//  NewImageViewController.h
//  Conecta
//
//  Created by Javier Berlana on 19/09/13.
//  Copyright (c) 2013 NSSpainTeam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewImageViewController : UIViewController

@property (strong, nonatomic) NSData *data;
@property (weak, nonatomic) IBOutlet UIImageView *imageReceived;


@end
