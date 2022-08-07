import 'dart:convert';

import '../util/im_util.dart';
import 'send_user.dart';

class ConversationLastMessage {
  final int messageId;
  final String type; // MessageType
  final String content;
  final SendUser user;
  final Map extra;

  ConversationLastMessage(
      this.messageId, this.type, this.content, this.user, this.extra);

  ConversationLastMessage.fromJson(Map data)
      : messageId = IMUtil.parseInt(data['messageId']),
        type = data['type'].toString(),
        content = data['content'],
        user = SendUser.fromJson(data['user']),
        extra = IMUtil.parseExtra(data['extra']);

  String toJson() {
    Map<String, dynamic> map = new Map();
    map['messageId'] = messageId;
    map['type'] = type;
    map['content'] = content;
    map['user'] = user.toMap();
    map['extra'] = extra;
    return json.encode(map);
  }

  @override
  String toString() {
    return 'ConversationLastMessage{messageId: $messageId, type: $type, content: $content, user: $user, extra: $extra}';
  }
}

class Conversation {
  final String targetId;
  final SendUser user;
  final String type; //private, group
  int sentTime;
  int unreadCount;
  bool isTop;
  ConversationLastMessage? lastMessage;
  int notify; //for group chat 1: notify 2：not notify
  int atCount; //@me

  String get key {
    return '$type.$targetId';
  }

  Conversation(this.type, this.targetId, this.user,
      {this.sentTime = 0,
      this.unreadCount = 0,
      this.isTop = false,
      this.lastMessage,
      this.notify = 1,
      this.atCount = 0});

  copyFrom(Conversation conv) {
    lastMessage = conv.lastMessage;
    sentTime = conv.sentTime;
    unreadCount = conv.unreadCount;
    isTop = conv.isTop;
    notify = conv.notify;
    atCount = conv.atCount;
  }

  // sql map to Conversation
  Conversation.fromMap(Map data)
      : type = '${data['type']}',
        targetId = '${data['senderId']}',
        sentTime = IMUtil.parseInt(data['sentTime']),
        unreadCount = IMUtil.parseInt(data['unreadCount']),
        isTop = (data['isTop'] == 1) ? true : false,
        lastMessage =
            ConversationLastMessage.fromJson(json.decode(data['lastMessage'])),
        user = SendUser.fromJson(jsonDecode(data['user'])),
        notify = data['notify'],
        atCount = IMUtil.parseInt(data['atCount']);

  // Conversation to sql map
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    map['type'] = type;
    map['senderId'] = targetId;
    map['sentTime'] = sentTime;
    map['unreadCount'] = unreadCount;
    map['isTop'] = isTop ? 1 : 0;
    map['lastMessage'] = (lastMessage != null) ? lastMessage!.toJson() : '';
    map['user'] = user.toJson();
    map['notify'] = notify;
    map['atCount'] = atCount;
    return map;
  }

  @override
  String toString() {
    return 'Conversation{type: $type, targetId: $targetId, sentTime: $sentTime, unreadCount: $unreadCount, isTop: $isTop, lastMessage: $lastMessage, notify: $notify, atCount: $atCount}';
  }
}
