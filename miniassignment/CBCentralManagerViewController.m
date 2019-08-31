//
//  CBCentralManagerViewController.m
//  CBTutorial
//
//  Created by Orlando Pereira on 10/8/13.
//  Copyright (c) 2013 Mobiletuts. All rights reserved.
//

#import "CBCentralManagerViewController.h"

@interface CBCentralManagerViewController ()
@property (strong, nonatomic) OpenGLView *cube;
@property (weak, nonatomic) IBOutlet UIView *cubeView;
@end

@implementation CBCentralManagerViewController
short gx=0;
short gy=0;
short gz=0;
short ax=0;
short ay=0;
short az=0;
short mx=0;
short my=0;
short mz=0;

unsigned int count;
float magnetoAvg, magnetoSum;
bool offset_done;
float Gyro_x_offset, Gyro_y_offset, Gyro_z_offset;

- (IBAction)disconnectFromSensor:(UIButton *)sender {
    if (_discoveredPeripheral != nil)
        [_centralManager cancelPeripheralConnection:_discoveredPeripheral];
    [_centralManager stopScan];
    _connectionStatus.text = @"Disconnected.";
}

- (IBAction)connectToSensor:(UIButton *)sender {
    
    if (_centralManager.state == CBManagerStatePoweredOn) {
        // scan for devices
        [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"FFF0"]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
        NSLog(@"Scanning started");
        _connectionStatus.text = @"Scanning...";
    }
}

-(void) viewDidAppear:(BOOL)animated
{
    //setup cubeView
    self.cube = [[OpenGLView alloc]
                 initWithFrame:self.cubeView.bounds];
    [self.cubeView addSubview:self.cube];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _data = [[NSMutableData alloc] init];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_discoveredPeripheral != nil)
        [_centralManager cancelPeripheralConnection:_discoveredPeripheral];
    [_centralManager stopScan];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBManagerStatePoweredOn) {
        return;
    }
    
//    if (central.state == CBManagerStatePoweredOn) {
//        // scan for devices
//        [_centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
//        NSLog(@"Scanning started");
//    }
//    if (central.state == CBManagerStatePoweredOn) {
//        // scan for devices
//        [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"FFF0"]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
//        NSLog(@"Scanning started");
//    }
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    NSLog(@"Advertisement data: %@", advertisementData);
    
    if (_discoveredPeripheral != peripheral) {
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        _discoveredPeripheral = peripheral;
        _discoveredPeripheral.delegate = self;
        // And connect
        NSLog(@"Connecting to peripheral %@", peripheral);
        _connectionStatus.text = @"Connecting to peripheral...";
        [_centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect");
    [self cleanup];
}

- (void)cleanup {
    
    // See if we are subscribed to a characteristic on the peripheral
    if (_discoveredPeripheral.services != nil) {
        for (CBService *service in _discoveredPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
                        if (characteristic.isNotifying) {
                            [_discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            return;
                        }
                    }
                }
            }
        }
    }
    
    if (_discoveredPeripheral != nil)
        [_centralManager cancelPeripheralConnection:_discoveredPeripheral];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected");
    _connectionStatus.text = @"Device Connected";
    
    [_centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    [_data setLength:0];
    
    peripheral.delegate = self;
    
    [peripheral discoverServices:@[[CBUUID UUIDWithString:@"FFF0"]]];

}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        [self cleanup];
        return;
    }
    
//    for (CBService *service in peripheral.services) {
//        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
//    }
    // Discover other characteristics
    
    for (CBService *service in peripheral.services) {
        NSLog(@"Service : %@", service);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        [self cleanup];
        return;
    }
    
//    for (CBCharacteristic *characteristic in service.characteristics) {
//        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
//            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
//        }
//    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Characteristic: %@", characteristic);
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error");
        return;
    }
    
    // NSLog(@"Characteristic updated: %@", characteristic);
    NSString *stringFromData = [self getHexStringFromNSData:characteristic.value];
    
    [_textview setText:stringFromData];
    [self extractData:characteristic.value];

    [_data appendData:characteristic.value];
    
    // After you have extracted the 9 values for accelerometer, gyroscope, and magnetometer
    
    offset_done = 0;
    if((count<60)&&(offset_done==0))
    {
        magnetoSum = magnetoSum + mx;
        count++;
    }
    else
    {
        magnetoAvg = fabs((float)magnetoSum/60.0);  // get avg of past 60 values of mx
        count=0;
        if(((magnetoAvg-abs(mx)<10)&&(magnetoAvg-abs(mx))>-10)&&(offset_done==0)) //make sure that cube is settled (△mx not more than 10)
        {
            Gyro_x_offset = gx;    //bear in mind that gyro is still in degrees at this point
            Gyro_y_offset = gy;
            Gyro_z_offset = gz;
            NSLog(@"offset set!\n");
            count=100;
            offset_done = 1;
        }
        magnetoSum = 0; //reset to 0 again
    }
    
    //Solve the zero error problem with the gyroscope
    gx = gx - Gyro_x_offset;
    gy = gy - Gyro_y_offset;
    gz = gz - Gyro_z_offset;
    
    // Show all 9 values of the sensors here
    
    //compute quaternion
    float gyro[3];
    gyro[0] = GLKMathDegreesToRadians(gx/14.375);
    gyro[1] = GLKMathDegreesToRadians(gy/14.375);
    gyro[2] = GLKMathDegreesToRadians(gz/14.375);
    
    
    MadgwickAHRSupdate(-gyro[0], -gyro[1], gyro[2], (float)ax, (float)ay, (float)az, (float)mx, (float)my, (float)mz);
    
    // Show all 4 values of quartenions here
    
    //display as yaw pitch roll
    float yaw, pitch, roll;
    quatToEuler(q1,q2,q0,q3,&yaw,&pitch,&roll);       //Originally q1, q2, q3
    
    yaw = GLKMathRadiansToDegrees(yaw);
    pitch = GLKMathRadiansToDegrees(pitch);
    roll = GLKMathRadiansToDegrees(roll);
    
    self.cube.yaw = yaw;
    self.cube.pitch = pitch;
    self.cube.roll = roll;
    
    // Display your yaw, pitch and roll values here
    // NSLog(@"Yaw: %.2f Pitch: %.2f Roll: %.2f\n", yaw, pitch, roll);
    _yawText.text = [[NSString alloc] initWithFormat:@"%.2f", yaw];
    _pitchText.text = [[NSString alloc] initWithFormat:@"%.2f", pitch];
    _rollText.text = [[NSString alloc] initWithFormat:@"%.2f", roll];

}

// For Quaternions to Euler conversion
void quatToEuler(float q0, float q1, float q2, float q3, float *yaw, float *pitch, float* roll)  {
    *yaw = atan2(2*(q0*q1 + q2*q3), 1-2*(q1*q1 + q2*q2));
    *pitch = asin(2*(q0*q2 - q3*q1));
    *roll = atan2(2*(q0*q3 + q1*q2), 1- 2*(q2*q2 + q3*q3));
}

- (void)extractData:(NSData *)data
{
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    
    NSUInteger dataLength  = [data length];
    unsigned short toRemoveFirstFourBits = 15;
    unsigned short toRemoveLastFourBits = 240;
    unsigned short toAddLeadingOnes = 61440;
    
    // gyroscope values are 16-bit
    gz = ((unsigned short)dataBuffer[18] << 8) + (unsigned short)dataBuffer[19];
    gy = ((unsigned short)dataBuffer[16] << 8) + (unsigned short)dataBuffer[17];
    gx = ((unsigned short)dataBuffer[14] << 8) + (unsigned short)dataBuffer[15];
    
    // magnetometer data 12-bit precision
    unsigned char mzhMSB = (dataBuffer[12] >> 3) & 0x1;
    unsigned char myhMSB = (dataBuffer[10] >> 3) & 0x1;
    unsigned char mxhMSB = (dataBuffer[8] >> 3) & 0x1;

    if (mzhMSB == 1) {
        mz =(((unsigned short)dataBuffer[12] << 8) | toAddLeadingOnes) + (unsigned short)dataBuffer[13];
    }
    else if (mzhMSB == 0)
        mz = (((unsigned short)dataBuffer[12] & toRemoveFirstFourBits) << 8) + (unsigned short)dataBuffer[13];
    if (myhMSB == 1)
        my =(((unsigned short)dataBuffer[10] << 8) | toAddLeadingOnes) + (unsigned short)dataBuffer[11];
    else if (myhMSB == 0)
        my = (((unsigned short)dataBuffer[10] & toRemoveFirstFourBits) << 8) + (unsigned short)dataBuffer[11];
    if (mxhMSB == 1)
        mx =(((unsigned short)dataBuffer[8] << 8) | toAddLeadingOnes) + (unsigned short)dataBuffer[9];
    else if (mxhMSB == 0)
        mx = (((unsigned short)dataBuffer[8] & toRemoveFirstFourBits) << 8) + (unsigned short)dataBuffer[9];
    
    // accelerometer data 12-bit precision
//    unsigned char azMSB = (dataBuffer[7] >> 7) & 0x1;
//    unsigned char ayMSB = (dataBuffer[5] >> 7) & 0x1;
//    unsigned char axMSB = (dataBuffer[5] >> 7) & 0x1;

    az = (((unsigned short)dataBuffer[6] & toRemoveLastFourBits)) + ((unsigned short)dataBuffer[7] << 8);
    ay = (((unsigned short)dataBuffer[4] & toRemoveLastFourBits)) + ((unsigned short)dataBuffer[5] << 8);
    ax = (((unsigned short)dataBuffer[2] & toRemoveLastFourBits)) + ((unsigned short)dataBuffer[3] << 8);

    unsigned int timestamp = (((unsigned int)dataBuffer[12] & toRemoveLastFourBits) << 16)+ (((unsigned int)dataBuffer[10] & toRemoveLastFourBits) << 12) + (((unsigned int)dataBuffer[8] & toRemoveLastFourBits) << 8) + (((unsigned int)dataBuffer[6] & toRemoveFirstFourBits) << 8) + (((unsigned int)dataBuffer[4] & toRemoveFirstFourBits) << 4) + ((unsigned int)dataBuffer[2] & toRemoveFirstFourBits);

    float gzFloat = (float)(gz * 1.0);
    float gyFloat = (float)(gy * 1.0);
    float gxFloat = (float)(gx * 1.0);
    
    float mzFloat = (float)(mz * 1.0);
    float myFloat = (float)(my * 1.0);
    float mxFloat = (float)(mx * 1.0);
    
    float azFloat = (float)(az * 1.0);
    float ayFloat = (float)(ay * 1.0);
    float axFloat = (float)(ax * 1.0);
    
    _gzText.text = [[NSString alloc] initWithFormat:@"%.1f", gzFloat];
    _gyText.text = [[NSString alloc] initWithFormat:@"%.1f", gyFloat];
    _gxText.text = [[NSString alloc] initWithFormat:@"%.1f", gxFloat];
    
    _mzText.text = [[NSString alloc] initWithFormat:@"%.1f", mzFloat];
    _myText.text = [[NSString alloc] initWithFormat:@"%.1f", myFloat];
    _mxText.text = [[NSString alloc] initWithFormat:@"%.1f", mxFloat];

    _azText.text = [[NSString alloc] initWithFormat:@"%.1f", azFloat];
    _ayText.text = [[NSString alloc] initWithFormat:@"%.1f", ayFloat];
    _axText.text = [[NSString alloc] initWithFormat:@"%.1f", axFloat];
    
    _timeStampText.text = [[NSString alloc] initWithFormat:@"%u", timestamp];
    
//    NSLog(@"%04hx", axTest);
//    NSLog(@"%hd", (short)axTest);
//    NSLog(@"%.2f", (float)((short)axTest * 1.0));


}
- (NSString *)getHexStringFromNSData:(NSData *)data
{
    /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
    
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    
    if (!dataBuffer)
    {
        return [NSString string];
    }
    
    NSUInteger          dataLength  = [data length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
    {
        [hexString appendFormat:@"%02x", (unsigned int)dataBuffer[i]];
    }
    
    return [NSString stringWithString:hexString];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
        return;
    }
    
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    } else {
        // Notification has stopped
        [_centralManager cancelPeripheralConnection:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    _discoveredPeripheral = nil;
}
@end
