//
//  CBCentralManagerViewController.h
//  CBTutorial
//
//  Created by Orlando Pereira on 10/8/13.
//  Copyright (c) 2013 Mobiletuts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#include "MadgwickAHRS.h"
#import "SERVICES.h"
#import <GLKit/GLKit.h>
#import "OpenGLView.h"
#include <math.h>

@interface CBCentralManagerViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) IBOutlet UITextView *textview;
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;
@property (strong, nonatomic) NSMutableData *data;
@property (strong, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) IBOutlet UILabel *connectionStatus;
@property (strong, nonatomic) IBOutlet UILabel *axText;
@property (strong, nonatomic) IBOutlet UILabel *ayText;
@property (strong, nonatomic) IBOutlet UILabel *azText;
@property (strong, nonatomic) IBOutlet UILabel *gxText;
@property (strong, nonatomic) IBOutlet UILabel *gyText;
@property (strong, nonatomic) IBOutlet UILabel *gzText;
@property (strong, nonatomic) IBOutlet UILabel *mxText;
@property (strong, nonatomic) IBOutlet UILabel *myText;
@property (strong, nonatomic) IBOutlet UILabel *mzText;
@property (strong, nonatomic) IBOutlet UILabel *timeStampText;
@property (strong, nonatomic) IBOutlet UILabel *yawText;
@property (strong, nonatomic) IBOutlet UILabel *pitchText;
@property (strong, nonatomic) IBOutlet UILabel *rollText;

@property (nonatomic) GLKQuaternion quaternion;

@end
