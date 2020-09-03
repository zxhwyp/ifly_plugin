#import "IflypluginPlugin.h"
#import "iflyplugin-prefix.pch"
#import <iflyMSC/IFlyMSC.h>

@interface IflypluginPlugin ()<IFlySpeechRecognizerDelegate>

@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;

@property (nonatomic, strong) FlutterMethodChannel* channel;

@end

@implementation IflypluginPlugin

- (instancetype)init {
    if (self = [super init]) {
        NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@", @"5f2b618a"];
        [IFlySpeechUtility createUtility:initString];
        _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
        _iFlySpeechRecognizer.delegate = self;
        [_iFlySpeechRecognizer setParameter:@"-1" forKey:@"audio_source"];
        [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
        [_iFlySpeechRecognizer setParameter: @"iat" forKey: @"domain"];
        [_iFlySpeechRecognizer setParameter: @"zh_cn" forKey: [IFlySpeechConstant LANGUAGE]];
        [_iFlySpeechRecognizer setParameter:@"16000" forKey:[IFlySpeechConstant SAMPLE_RATE]];
        [_iFlySpeechRecognizer setParameter:@"1" forKey:[IFlySpeechConstant ASR_PTT]];

    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
  IflypluginPlugin* instance = [[IflypluginPlugin alloc] init];
    instance.channel = [FlutterMethodChannel
        methodChannelWithName:@"iflyplugin"
              binaryMessenger:[registrar messenger]];
  [registrar addMethodCallDelegate:instance channel:instance.channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"recognizer" isEqualToString:call.method]) {
      NSString *path = (NSString *)call.arguments;
      [self recognizer:path];
      result(@0);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)recognizer:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    if (!data) {
        [self.channel invokeMethod:@"tip" arguments:@"音频文件无效"];
        return;
    }
    [self.iFlySpeechRecognizer startListening];
    [self.iFlySpeechRecognizer writeAudio:data];
    [self.iFlySpeechRecognizer stopListening];//音频数据写入完成，进入等待状态
}

- (void)onCompleted:(IFlySpeechError *)errorCode {
    if (errorCode.errorCode != 0) {
        [self.channel invokeMethod:@"tip" arguments: errorCode.errorDesc];
    }
}

- (void)onResults:(NSArray *)results isLast:(BOOL)isLast {
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    NSString *resultFromJson = [self stringFromJson:resultString];
    [self.channel invokeMethod:@"result" arguments:resultFromJson];
}

- (NSString *)stringFromJson:(NSString*)params
{
    if (params == NULL) {
        return nil;
    }
    
    NSMutableString *tempStr = [[NSMutableString alloc] init];
    NSDictionary *resultDic  = [NSJSONSerialization JSONObjectWithData:
                                [params dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];

    if (resultDic!= nil) {
        NSArray *wordArray = [resultDic objectForKey:@"ws"];
        
        for (int i = 0; i < [wordArray count]; i++) {
            NSDictionary *wsDic = [wordArray objectAtIndex: i];
            NSArray *cwArray = [wsDic objectForKey:@"cw"];
            
            for (int j = 0; j < [cwArray count]; j++) {
                NSDictionary *wDic = [cwArray objectAtIndex:j];
                NSString *str = [wDic objectForKey:@"w"];
                [tempStr appendString: str];
            }
        }
    }
    return tempStr;
}

@end
