//
//  OpenGLView.m
//  BLEAngle
//
//  Created by Phan on 26/12/14.
//  Copyright (c) 2014 Homerehab. All rights reserved.
//

#import "OpenGLView.h"
#import "CC3Math/CC3GLMatrix.h"

@interface OpenGLView()

@property (strong,nonatomic) CADisplayLink* displayLink;
@property (strong,nonatomic) UILabel *yawLabel,*pitchLabel,*rollLabel;

@end

@implementation OpenGLView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

const Vertex Vertices[] = {
    
    //Directions according to arrow pointing down
    
    {{1.2, 0, 1}, {0, 1, 0, 1}},         //Green (Top, NE)
    {{1.2, 1.0, 1}, {0, 0, 1, 1}},          //Blue (Btm, SW)
    {{-1.2, 1.0, 1}, {0, 0, 1, 1}},         //Blue (Btm, SE)
    {{-1.2, 0, 1}, {0, 1, 0, 1}},        //Green (Top, NW)
    {{1.2, 0, -1}, {0, 1, 1, 1}},        //Cyan   (Top, SE)
    {{1.2, 1.0, -1}, {0, 0, 1, 1}},         //Blue  (Btm, NW)
    {{-1.2, 1.0, -1}, {0, 0, 1, 1}},        //Blue  (Btm, NE)
    {{-1.2, 0, -1}, {0, 1, 1, 1}}        //Cyan  (Top, Sw)

    
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 7, 6,
    // Left
    2, 7, 3,
    7, 6, 2,
    // Right
    0, 4, 1,
    4, 1, 5,
    // Top
    6, 2, 1,
    1, 6, 5,
    // Bottom
    0, 3, 7,
    0, 7, 4
};

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;
}

- (void)setupContext {
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
}

- (void)setupFrameBuffer {
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

- (void)render:(CADisplayLink*)displayLink {
    glClearColor(255.0/255.0, 255.0/255.0, 255.0/255.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    float h = 4.0f * self.frame.size.height / self.frame.size.width;
    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h/2 andTop:h/2 andNear:4 andFar:10];
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    CC3GLMatrix *modelView = [CC3GLMatrix matrix];
    [modelView populateFromTranslation:CC3VectorMake(0, 0, -7)];
    
    //To fix the original orientation of the cube
//    [modelView rotateByX:(90)];
//    [modelView rotateByZ:(0)];
//    [modelView rotateByY:(90)];
    
    [modelView rotateBy:CC3VectorMake(_pitch, _roll, _yaw)];
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
    
    // 1
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    // 2
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
    // 3
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]),
                   GL_UNSIGNED_BYTE, 0);
    
    [EAGLContext setCurrentContext:_context];
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
    
    // 1
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // 2
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // 3
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4
    glCompileShader(shaderHandle);
    
    // 5
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
    
}

- (void)compileShaders {
    
    // 1
    GLuint vertexShader = [self compileShader:@"SimpleVertex"
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment"
                                       withType:GL_FRAGMENT_SHADER];
    
    // 2
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    // 3
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    // 4
    glUseProgram(programHandle);
    
    // 5
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    _modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
}

- (void)setupVBOs {
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
}

- (void)setupDisplayLink {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

// Replace initWithFrame with this
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContext];
        [self setupDepthBuffer];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self compileShaders];
        [self setupVBOs];
        [self setupDisplayLink];
        
        self.yawLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 15)];
        self.pitchLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 80, 15)];
        self.rollLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, 80, 15)];
        [self addSubview:self.yawLabel];
        [self addSubview:self.pitchLabel];
        [self addSubview:self.rollLabel];
    }
    return self;
}

-(void)stopRender {
    
    [[NSRunLoop currentRunLoop] cancelPerformSelectorsWithTarget:self];
    [self.displayLink invalidate];
    self.displayLink = nil;
    self.context = nil;
    self.eaglLayer = nil;
    //NSLog(@"stopRender stopped");
}

-(void)setYaw:(float)yaw {
    _yaw = yaw;
    dispatch_async(dispatch_get_main_queue(), ^{
        //self.yawLabel.text = [NSString stringWithFormat:@"%f",yaw];
    });
}

-(void)setPitch:(float)pitch {
    _pitch = pitch;
    dispatch_async(dispatch_get_main_queue(), ^{
        //self.pitchLabel.text = [NSString stringWithFormat:@"%f",pitch];
    });
}

-(void)setRoll:(float)roll {
    _roll = roll;
    dispatch_async(dispatch_get_main_queue(), ^{
        //self.rollLabel.text = [NSString stringWithFormat:@"%f",roll];
    });
}

@end