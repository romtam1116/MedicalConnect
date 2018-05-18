
#import "SINCallKitProvider.h"
#import "AudioControllerDelegate.h"
#import <Sinch/Sinch.h>

static CXCallEndedReason SINGetCallEndedReason(SINCallEndCause cause) {
  switch (cause) {
    case SINCallEndCauseError:
      return CXCallEndedReasonFailed;
    case SINCallEndCauseDenied:
      return CXCallEndedReasonRemoteEnded;
    case SINCallEndCauseHungUp:
      // This mapping is not really correct, as SINCallEndCauseHungUp is the end case also when the local peer ended the
      // call.
      return CXCallEndedReasonRemoteEnded;
    case SINCallEndCauseTimeout:
      return CXCallEndedReasonUnanswered;
    case SINCallEndCauseCanceled:
      return CXCallEndedReasonUnanswered;
    case SINCallEndCauseNoAnswer:
      return CXCallEndedReasonUnanswered;
    case SINCallEndCauseOtherDeviceAnswered:
      return CXCallEndedReasonUnanswered;
    default:
      break;
  }
  return CXCallEndedReasonFailed;
}

@interface SINCallKitProvider () {
  id<SINClient> _client;
  CXProvider *_provider;
  AudioContollerDelegate *_acDelegate;
  NSMutableDictionary<NSUUID *, id<SINCall>> *_calls;
  BOOL _muted;
}
@end

@implementation SINCallKitProvider

- (instancetype)initWithClient:(id<SINClient>)client {
  self = [super init];
  if (self) {
    _client = client;
    _muted = NO;
    _acDelegate = [[AudioContollerDelegate alloc] init];
    _client.audioController.delegate = _acDelegate;
    _calls = [NSMutableDictionary dictionary];
    CXProviderConfiguration *config = [[CXProviderConfiguration alloc] initWithLocalizedName:@"CODI-C"];
//    config.iconTemplateImageData = UIImagePNGRepresentation([UIImage imageNamed:@"callkit_icon"]);
    config.maximumCallGroups = 1;
    config.maximumCallsPerCallGroup = 1;
    config.supportsVideo = YES;
    config.ringtoneSound = @"incoming.wav";

    _provider = [[CXProvider alloc] initWithConfiguration:config];
    [_provider setDelegate:self queue:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callDidEnd:)
                                                 name:SINCallDidEndNotification
                                               object:nil];
  }
  return self;
}

- (void)reportNewIncomingCall:(id<SINCall>)call headers:(NSDictionary *)headers {
  CXCallUpdate *update = [[CXCallUpdate alloc] init];
  NSString *remoteName =  headers[@"display_name"] ? headers[@"display_name"] : @"Unknown";
  BOOL hasVideo =  headers[@"type"] != nil ? ([headers[@"type"] isEqualToString:@"v"] ? YES : NO) : NO;
  update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:remoteName];
  update.hasVideo = hasVideo;

  [_provider reportNewIncomingCallWithUUID:[[NSUUID alloc] initWithUUIDString:call.callId]
                                    update:update
                                completion:^(NSError *_Nullable error) {
                                  if (!error) {
                                    [self addNewCall:call];
                                  }
                                }];
}

- (void)addNewCall:(id<SINCall>)call {
  NSLog(@"addNewCall: Adding call: %@", call.callId);
  [_calls setObject:call forKey:[[NSUUID alloc] initWithUUIDString:call.callId]];
}

// Handle cancel/bye event initiated by either caller or callee
- (void)callDidEnd:(NSNotification *)notification {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"sinchCallDidEnd" object:nil];
  
  id<SINCall> call = [notification userInfo][SINCallKey];
  if (call) {
    if (call.details.establishedTime) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"callShouldUpdateHistory" object:nil];
    }
    
    [_provider reportCallWithUUID:[[NSUUID alloc] initWithUUIDString:call.callId]
                      endedAtDate:call.details.endedTime
                           reason:SINGetCallEndedReason(call.details.endCause)];
  } else {
    NSLog(@"WARNING: No Call was reported as ended on SINCallDidEndNotification");
  }

  if ([self callExists:call.callId]) {
    NSLog(@"callDidEnd, Removing call: %@", call.callId);
    [_calls removeObjectForKey:[[NSUUID alloc] initWithUUIDString:call.callId]];
  }
}

- (BOOL)callExists:(NSString*)callId {
  if ([_calls count] == 0) {
    return NO;
  }

  for (id<SINCall> callKitCall in _calls.allValues) {
    if ([callKitCall.callId isEqualToString:callId]) {
      return YES;
    }
  }
  return NO;
}

- (NSArray *)activeCalls {
  return [[_calls allValues] copy];
}

- (id<SINCall>)currentEstablishedCall {
  NSArray *calls = [self activeCalls];
  if (calls && [calls count] == 1 && ([calls[0] state] == SINCallStateEstablished || [calls[0] state] == SINCallStateInitiating)) {
    return calls[0];
  } else {
    return nil;
  }
}
#pragma mark - CXProviderDelegate

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
  [_client.callClient provider:provider didActivateAudioSession:audioSession];
}

- (id<SINCall>)callForAction:(CXCallAction *)action {
  id<SINCall> call = [_calls objectForKey:action.callUUID];
  if (!call) {
    NSLog(@"WARNING: No call found for (%@)", action.callUUID);
  }
  return call;
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
  [[self callForAction:action] answer];
  [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
  [[self callForAction:action] hangup];
  [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
  NSLog(@"-[CXProviderDelegate performSetMutedCallAction:]");

  if (_acDelegate.muted) {
    [[_client audioController] unmute];
  } else {
    [[_client audioController] mute];
  }

  [action fulfill];
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
  NSLog(@"-[CXProviderDelegate didDeactivateAudioSession:]");
}

- (void)providerDidReset:(CXProvider *)provider {
  NSLog(@"-[CXProviderDelegate providerDidReset:]");
}

@end
