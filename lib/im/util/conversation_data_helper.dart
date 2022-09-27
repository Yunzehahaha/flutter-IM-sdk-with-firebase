import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:im_sdk/im/im_client.dart';
import 'package:im_sdk/im/util/user_info_lookup.dart';
import '../db/db_helper.dart';
import '../model/conversation.dart';
import '../model/message_content.dart';
import '../model/send_user.dart';
import '../protocol/common_define.dart';
import 'msg.util.dart';

class ConversationDataHelper {
  static Future<void> updateOrInsertConversation(MessageContent msgContent,
      String senderUserId, FirebaseFirestore firebaseFirestore) async {
    final DatabaseHelper db = DatabaseHelper();

    SendUser sendUser = SendUser(
        msgContent.user.id, msgContent.user.name, msgContent.user.portraitUri);
    ConversationLastMessage lastMessage = ConversationLastMessage(
        msgContent.messageId,
        msgContent.type,
        msgContent.content,
        sendUser,
        (msgContent.extra.isNotEmpty) ? json.decode(msgContent.extra) : null);

    ///会话targetId（userId or groupId）需要转换下，不能是自己
    String conversationTargetId = "";
    if (msgContent.conversationType == ConversationType.private.name) {
      ///自己发送的消息conversationTargetId 就是消息接收方的id， 收到别人的消息，conversationTargetId 就是发送方的id
      conversationTargetId = (msgContent.fromMe(IMClient.currentUser.id))
          ? msgContent.receiverId
          : msgContent.senderId;
    } else if (msgContent.conversationType == ConversationType.group.name) {
      ///群聊会话targetId始终为群Id;
      conversationTargetId = msgContent.senderId;
    }

    ///判断`Conversation`表中是否已有对应会话记录，没有则insert，有则update (unreadCount+1，lastMessage，lastSentTime)
    Conversation? conversation = await db.getConversation(
        msgContent.conversationType, conversationTargetId);
    if (conversation == null) {
      if ((msgContent.fromMe(IMClient.currentUser.id))) {
        //拉取firebase user的信息
        UserInfoLookup lookup = UserInfoLookup(firebaseFirestore);
        SendUser user = await lookup.getUser(msgContent.receiverId) ?? sendUser;
        conversation = Conversation(
            msgContent.conversationType, conversationTargetId, user);
      } else {
        conversation = Conversation(
            msgContent.conversationType, conversationTargetId, sendUser);
      }

      conversation.sentTime = msgContent.sentTime;
      if (msgContent.user.id == senderUserId) {
        conversation.unreadCount = 0;
      } else {
        conversation.unreadCount = 1;
        conversation.atCount = MessageUtil.checkMsgHasAtYou(msgContent) ? 1 : 0;
      }
      conversation.isTop = false;
      conversation.lastMessage = lastMessage;
      log("insertConversation data = ${conversation.toMap()}");
      await db.insertConversation(conversation);
    } else {
      Map<String, dynamic> values = <String, dynamic>{};
      if (!msgContent.fromMe(IMClient.currentUser.id)) {
        values['unreadCount'] = conversation.unreadCount + 1;
        bool hasAtYou = MessageUtil.checkMsgHasAtYou(msgContent);
        values['atCount'] = (conversation.atCount) + (hasAtYou ? 1 : 0);
      }
      values['sentTime'] = msgContent.sentTime;
      values['lastMessage'] = lastMessage.toJson();
      log('unreadCount = ${values['unreadCount']}');
      await db.updateConversation(
          msgContent.conversationType, conversationTargetId, values);
    }
  }
}
