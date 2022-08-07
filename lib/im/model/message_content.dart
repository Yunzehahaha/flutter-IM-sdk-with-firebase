import 'dart:convert';

import '../util/im_util.dart';
import 'send_user.dart';

class MessageContent {
  int messageId; //for client app internal usage
  int messageUid; //for client app and server sync usage
  String type;
  String conversationType;
  SendUser user;
  String targetId;
  String senderId;
  String receiverId;
  String content;
  int sentTime;
  String status;
  String imageUrl;
  String audioUrl;
  int duration;
  String extra;

  MessageContent(
      {required this.type,
      required this.conversationType,
      required this.messageUid,
      required this.user,
      required this.targetId,
      required this.senderId,
      required this.receiverId,
      this.audioUrl = '',
      this.duration = 0,
      this.extra = '{}',
      this.imageUrl = '',
      required this.messageId,
      required this.sentTime,
      required this.status,
      required this.content});

  Map<String, dynamic> toLocalDbMap() {
    Map<String, dynamic> map = {};
    map['type'] = type;
    map['conversationType'] = conversationType;
    map["user"] = user.toJson();
    map["senderId"] = senderId;
    map["receiverId"] = receiverId;
    // map["messageId"] = messageId;
    map["targetId"] = targetId;
    map["content"] = content;
    map["sentTime"] = sentTime;
    map["status"] = status;
    map["imageUrl"] = imageUrl;
    map["audioUrl"] = audioUrl;
    map["duration"] = duration;
    map['messageUid'] = messageUid;
    map["extra"] = extra;
    return map;
  }

  bool fromMe(String id) {
    return senderId == id;
  }

  Map<String, dynamic> toFirebaseMap() {
    Map<String, dynamic> map = {};
    map['type'] = type;
    map['conversationType'] = conversationType;
    map["user"] = user.toMap();
    map["senderId"] = senderId;
    map["receiverId"] = receiverId;
    // map["messageId"] = messageId;
    map["content"] = content;
    map["sentTime"] = sentTime;
    map["status"] = status;
    map["imageUrl"] = imageUrl;
    map["audioUrl"] = audioUrl;
    map["duration"] = duration;
    map['messageUid'] = messageUid;
    map["extra"] = extra;
    return map;
  }

  MessageContent.fromFirebaseJson(Map<String, dynamic> data)
      : type = data['type'],
        conversationType = data['conversationType'],
        user = SendUser.fromJson(IMUtil.parseToMap(data['user'])),
        messageUid = data['messageUid'],
        senderId = data['senderId'],
        receiverId = data['receiverId'],
        messageId = data['messageId'] ?? 0,
        sentTime = data['sentTime'],
        status = data['status'],
        content = data['content'] ?? '',
        audioUrl = data['audioUrl'] ?? '',
        duration = data['duration'] ?? 0,
        extra = data['extra'] ?? '{}',
        targetId = data['senderId'],
        imageUrl = data['imageUrl'] ?? '';

  MessageContent.fromDbJson(Map<String, dynamic> data)
      : type = data['type'],
        conversationType = data['conversationType'],
        user = SendUser.fromJson(IMUtil.parseToMap(data['user'])),
        messageUid = data['messageUid'],
        senderId = data['senderId'],
        receiverId = data['receiverId'],
        messageId = data['messageId'] ?? 0,
        sentTime = data['sentTime'],
        status = data['status'],
        content = data['content'] ?? '',
        audioUrl = data['audioUrl'] ?? '',
        duration = data['duration'] ?? 0,
        extra = data['extra'] ?? '{}',
        targetId = data['targetId'],
        imageUrl = data['imageUrl'] ?? '';
}
