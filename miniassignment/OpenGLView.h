//
//  OpenGLView.h
//  BLEAngle
//
//  Created by Phan on 26/12/14.
//  Copyright (c) 2014 Homerehab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface OpenGLView : UIView

@property (strong,nonatomic) CAEAGLLayer *eaglLayer;
@property (strong,nonatomic) EAGLContext *context;
@property (nonatomic) GLuint colorRenderBuffer;
@property (nonatomic) GLuint positionSlot;
@property (nonatomic) GLuint colorSlot;
@property (nonatomic) GLuint projectionUniform;
@property (nonatomic) GLuint modelViewUniform;
@property (nonatomic) float yaw;
@property (nonatomic) float pitch;
@property (nonatomic) float roll;
@property (nonatomic) GLuint depthRenderBuffer;

-(void)stopRender;

@end
