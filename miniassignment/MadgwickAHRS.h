//
//  MadgwickAHRS.h
//  Home Rehab
//
//  Created by Nicholas on 23/3/15.
//  Copyright (c) 2015 Phan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface MadgwickAHRS : NSObject

@property (nonatomic) float beta;				// algorithm gain
@property (nonatomic) float q0, q1, q2, q3;	// quaternion of sensor frame relative to auxiliary frame

-(GLKQuaternion)MadgwickAHRSupdateWithGyroX:(float)gx andGyroY:(float)gy andGyroZ:(float)gz andAccX:(float)ax andAccY:(float)ay andAccZ:(float)az andMagX:(float)mx andMagY:(float)my andMagZ:(float)mz;
-(GLKQuaternion)MadgwickAHRSupdateIMUWithGyroX:(float)gx andGyroY:(float)gy andGyroZ:(float)gz andAccX:(float)ax andAccY:(float)ay andAccZ:(float)az;

@end
