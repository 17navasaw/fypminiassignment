//
//  CBCentralManagerViewController.m
//  CBTutorial
//
//  Created by Orlando Pereira on 10/8/13.
//  Copyright (c) 2013 Mobiletuts. All rights reserved.
//

#import "CBCentralManagerViewController.h"

@interface CBCentralManagerViewController ()
@end

@implementation CBCentralManagerViewController
float gx=0.0;
float gy=0.0;
float gz=0.0;
float ax=0.0;
float ay=0.0;
float az=0.0;
float mx=0.0;
float my=0.0;
float mz=0.0;

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
    
    NSLog(@"Characteristic updated: %@", characteristic);
    NSString *stringFromData = [self getHexStringFromNSData:characteristic.value];
    // NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    [_textview setText:stringFromData];
    [self extractData:characteristic.value];

    [_data appendData:characteristic.value];
//    [_textview setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];

//    // Have we got everything we need?
//    if ([stringFromData isEqualToString:@"EOM"]) {
//
//        [_textview setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
//
//        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
//
//        [_centralManager cancelPeripheralConnection:peripheral];
//    }
    
//    [_data appendData:characteristic.value];
}

- (void)extractData:(NSData *)data
{
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    
    NSUInteger dataLength  = [data length];
    unsigned short toRemoveFirstFourBits = 15;
    unsigned short toRemoveLastFourBits = 240;
    unsigned short toAddLeadingOnes = 61440;
    
    // gyroscope values are 16-bit
    unsigned short gzTest = ((unsigned short)dataBuffer[18] << 8) + (unsigned short)dataBuffer[19];
    unsigned short gyTest = ((unsigned short)dataBuffer[16] << 8) + (unsigned short)dataBuffer[17];
    unsigned short gxTest = ((unsigned short)dataBuffer[14] << 8) + (unsigned short)dataBuffer[15];
    
    // magnetometer data 12-bit precision
    unsigned char mzhMSB = (dataBuffer[12] >> 3) & 0x1;
    unsigned char myhMSB = (dataBuffer[10] >> 3) & 0x1;
    unsigned char mxhMSB = (dataBuffer[8] >> 3) & 0x1;

    unsigned short mzTest;
    unsigned short myTest;
    unsigned short mxTest;

    if (mzhMSB == 1) {
        mzTest =(((unsigned short)dataBuffer[12] << 8) | toAddLeadingOnes) + (unsigned short)dataBuffer[13];
    }
    else if (mzhMSB == 0)
        mzTest = (((unsigned short)dataBuffer[12] & toRemoveFirstFourBits) << 8) + (unsigned short)dataBuffer[13];
    if (myhMSB == 1)
        myTest =(((unsigned short)dataBuffer[10] << 8) | toAddLeadingOnes) + (unsigned short)dataBuffer[11];
    else if (myhMSB == 0)
        myTest = (((unsigned short)dataBuffer[10] & toRemoveFirstFourBits) << 8) + (unsigned short)dataBuffer[11];
    if (mxhMSB == 1)
        mxTest =(((unsigned short)dataBuffer[8] << 8) | toAddLeadingOnes) + (unsigned short)dataBuffer[9];
    else if (mxhMSB == 0)
        mxTest = (((unsigned short)dataBuffer[8] & toRemoveFirstFourBits) << 8) + (unsigned short)dataBuffer[9];
    
    // accelerometer data 12-bit precision
    unsigned short azTest = (((unsigned short)dataBuffer[6] & toRemoveLastFourBits) >> 4) + ((unsigned short)dataBuffer[7] << 4);
    unsigned short ayTest = (((unsigned short)dataBuffer[4] & toRemoveLastFourBits) >> 4) + ((unsigned short)dataBuffer[5] << 4);
    unsigned short axTest = (((unsigned short)dataBuffer[2] & toRemoveLastFourBits) >> 4) + ((unsigned short)dataBuffer[3] << 4);

    unsigned int timestamp = (((unsigned int)dataBuffer[12] & toRemoveLastFourBits) << 16)+ (((unsigned int)dataBuffer[10] & toRemoveLastFourBits) << 12) + (((unsigned int)dataBuffer[8] & toRemoveLastFourBits) << 8) + (((unsigned int)dataBuffer[6] & toRemoveFirstFourBits) << 8) + (((unsigned int)dataBuffer[4] & toRemoveFirstFourBits) << 4) + ((unsigned int)dataBuffer[2] & toRemoveFirstFourBits);

    gz = (float)((short)gzTest * 1.0);
    gy = (float)((short)gyTest * 1.0);
    gx = (float)((short)gxTest * 1.0);
    
    mz = (float)((short)mzTest * 1.0);
    my = (float)((short)myTest * 1.0);
    mx = (float)((short)mxTest * 1.0);
    
    _gzText.text = [[NSString alloc] initWithFormat:@"%.1f", gz];
    _gyText.text = [[NSString alloc] initWithFormat:@"%.1f", gy];
    _gxText.text = [[NSString alloc] initWithFormat:@"%.1f", gx];
    
    _mzText.text = [[NSString alloc] initWithFormat:@"%.1f", mz];
    _myText.text = [[NSString alloc] initWithFormat:@"%.1f", my];
    _mxText.text = [[NSString alloc] initWithFormat:@"%.1f", mx];

//    NSLog(@"%04hx", gzTest);
//    NSLog(@"%hd", (short)gzTest);
//    NSLog(@"%.2f", (float)((short)gzTest * 1.0));


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
