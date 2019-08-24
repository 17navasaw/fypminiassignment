//
//  VideoViewController.m
//  test
//
//  Created by Aw Wen Hao on 18/8/19.
//  Copyright © 2019 Aw Wen Hao. All rights reserved.
//

#import "VideoViewController.h"
#import "YTPlayerView.h"

@interface VideoViewController ()
@property (strong, nonatomic) IBOutlet YTPlayerView *playerView;

@end

@implementation VideoViewController

#define API_KEY "AIzaSyCeJWx4y5S1fa_wHMaS0uWZmyjH8_p_-pc";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.playerView.delegate = self;
    NSDictionary *playerVars = @{
                                 @"playsinline": @1,
                                 };
    [self.playerView loadWithVideoId:@"M7lc1UVf-VE" playerVars:playerVars];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)playVideo:(id)sender {
    [self.playerView playVideo];
}

- (IBAction)stopVideo:(id)sender {
    [self.playerView stopVideo];
}

- (void)playerView:(YTPlayerView *)playerView didChangeToState:(YTPlayerState)state {
    switch (state) {
        case kYTPlayerStatePlaying:
            NSLog(@"Started playback");
            break;
        case kYTPlayerStatePaused:
            NSLog(@"Paused playback");
            break;
        default:
            break;
    }
}
@end
