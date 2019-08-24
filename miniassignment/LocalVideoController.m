//
//  LocalVideoController.m
//  miniassignment
//
//  Created by ACTLab on 8/22/19.
//  Copyright © 2019 Wen Hao. All rights reserved.
//

#import "LocalVideoController.h"

@interface LocalVideoController ()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerViewController *playerViewController;
@end

@implementation LocalVideoController
//AVPlayer *player;
//AVPlayerViewController *playerViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *urlString = [[NSBundle mainBundle] pathForResource:@"trailer" ofType:@"mp4"];

    if (urlString) {
        NSURL *url = [[NSURL alloc] initFileURLWithPath:urlString];
        self.player = [AVPlayer playerWithURL:url];
        self.playerViewController = [[AVPlayerViewController alloc] init];
        self.playerViewController.player = self.player;
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:NULL error:NULL];
}

- (IBAction)playVideo:(UIButton *)sender {
//    NSString *urlString = [[NSBundle mainBundle] pathForResource:@"trailer" ofType:@"mp4"];
//
//    if (urlString) {
//        NSLog(@"urlstring not null");
//        NSURL *url = [[NSURL alloc] initFileURLWithPath:urlString];
    
    [self presentViewController:self.playerViewController animated:YES completion:^{
        [self.playerViewController.player play];
    }];
//    }
}

@end
