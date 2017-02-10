//
//  ViewController.m
//  SocketDemo
//
//  Created by vbn on 2017/2/9.
//  Copyright © 2017年 vbn. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"


@interface ViewController ()<GCDAsyncSocketDelegate>

@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (strong, nonatomic) GCDAsyncSocket *socket;

@property (strong, nonatomic) NSMutableData *responseData;

@property (assign, nonatomic) uint64_t responseLength;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setup];
}


- (void)setup {
    self.responseData = [NSMutableData data];
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self connect];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)connect {
    NSError *error ;
    [self.socket connectToHost:@"localhost" onPort:7891 error:&error];
    if (error) {
        NSLog(@"connetct error %@",error);
    }
}

- (IBAction)sendAction:(id)sender {
    NSString *requestStr = [NSString stringWithFormat:@"This data is from Iphone Client"];
    NSData *requestData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.socket writeData:requestData withTimeout:-1 tag:1];
    [self.socket readDataWithTimeout:-1 tag:1];
    
}
- (IBAction)reconnectAdction:(id)sender {
    if (self.socket.isDisconnected) {
        [self connect];
    }
    
}
- (IBAction)disconnectAction:(id)sender {
    if (self.socket.isConnected) {
        [self.socket disconnect];
    }
}


#pragma mark - GCDAsyncSocket Delegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"socket:%p didConnectToHost:%@ port:%hu", sock, host, port);
    [sock readDataWithTimeout:-1 tag:123];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"socket:%p didReadData:withTag:%ld", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"socket:%p didReadData:withTag:%ld", sock, tag);
    Byte *bytes = (Byte *)data.bytes;
    NSData *headerData = [data subdataWithRange:NSMakeRange(0, 6)];
    NSString *headerDataString = [[NSString alloc] initWithData:headerData encoding:NSUTF8StringEncoding];
    if ([headerDataString isEqualToString:@"header"]) {
        
        NSData *lengthData = [data subdataWithRange:NSMakeRange(6, 8)];
        uint64_t length = 0;
        [lengthData getBytes:&length length:lengthData.length];
        length = CFSwapInt64HostToBig(length);
        NSLog(@"length is %lld",length);
        self.responseLength = length+14;
        [self.responseData appendData:data];
        if (self.responseLength == self.responseData.length) {
            NSString *httpResponse = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
//            NSString* str = [NSString stringWithUTF8String:[[self.responseData subdataWithRange:NSMakeRange(14, self.responseLength - 14)] bytes]];
            NSLog(@"接收完毕:\n%@--------", httpResponse);
            self.textView.text = httpResponse;
            [sock readDataWithTimeout:-1 tag:1];
            self.responseData = [NSMutableData data];
            self.responseLength = 0;
        }
        [sock readDataWithTimeout:-1 tag:1];
        
    } else if (tag == 1){
        [self.responseData appendData:data];
        if (self.responseData.length == self.responseLength) {
            NSString *httpResponse = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
            NSLog(@"接收完毕:\n%@-------", httpResponse);
            self.textView.text = httpResponse;
            NSRange range = NSMakeRange(self.textView.text.length - 1, 1);
            [self.textView scrollRangeToVisible:range];
            [sock readDataWithTimeout:-1 tag:1];
            self.responseData = [NSMutableData data];
            self.responseLength = 0;
        } else {
            NSLog(@"未接收完毕");
            [sock readDataWithTimeout:-1 tag:1];
        }
    } else {
        NSString *httpResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSLog(@"接收的数据为:\n%@", httpResponse);
        self.textView.text = httpResponse;
        [sock readDataWithTimeout:-1 tag:1];
    }
    
    for (int i = 0; i<@"header".length+8; i++) {
        NSLog(@"i=%d,byte is %hhu",i,bytes[i]);
    }
    
//    NSLog(@"packPacker length is %c",length);
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"socketDidDisconnect:%p withError: %@", sock, err);
    NSLog(@"断开连接");
}

@end
