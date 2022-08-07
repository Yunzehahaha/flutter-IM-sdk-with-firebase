import 'dart:developer';

import 'package:sqflite/sqflite.dart';

import '../model/conversation.dart';
import '../model/message_content.dart';
import '../protocol/common_define.dart';
import 'db_init.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get db async {
    return await DatabaseInit().db;
  }

  Future<List<Conversation>> getConversationList() async {
    List<Conversation> res = [];
    var dbClient = await db;
    List<Map<String, dynamic>> records =
        await dbClient.rawQuery("SELECT * FROM `Conversation`");

    records.forEach((element) {
      Conversation conversation = Conversation.fromMap(element);
      //IMLog.d(LOG_TAG, "conversation = ${element.toString()}");
      res.add(conversation);
    });
    return res;
  }

  Future<Conversation?> getConversation(String type, String senderId) async {
    var dbClient = await db;
    List<Map<String, dynamic>> records = await dbClient.rawQuery(
        "SELECT * FROM `Conversation` WHERE `senderId`='$senderId' AND `type`='$type'");
    log("getConversation and type = $type, and senderId = $senderId and records length = ${records.length}");
    if (records.isNotEmpty) {
      return Conversation.fromMap(records.first);
    }
    return null;
  }

  Future<bool> updateConversation(
      String type, String senderId, Map<String, dynamic> values) async {
    var dbClient = await db;
    int changedRows = await dbClient.update("Conversation", values,
        where: "`senderId` = ? AND `type`= ?", whereArgs: [senderId, type]);
    return changedRows == 1;
  }

  Future<bool> insertConversation(Conversation conversation) async {
    var dbClient = await db;
    int id = await dbClient.insert("Conversation", conversation.toMap());
    return true;
  }

  Future<bool> removeConversation(String type, String senderId) async {
    var dbClient = await db;
    int changedRows = await dbClient.delete("Conversation",
        where: "senderId = ? AND type = ?", whereArgs: [senderId, type]);
    return (changedRows >= 1) ? true : false;
  }

  Future<List<MessageContent>> getHistoryMessages(
      String type, String targetId, int oldestMessageId, int count,
      {bool excludeDelete = true}) async {
    List<MessageContent> res = [];
    var dbClient = await db;
    log('getting mesaage history targetId: $targetId');
    String whereStr =
        "WHERE `targetId`='$targetId' AND `conversationType`='$type' ";
    if (oldestMessageId > 0) {
      whereStr =
          "WHERE `targetId`='$targetId' AND `conversationType`='$type' AND `messageId` < $oldestMessageId ";
    }

    List<Map<String, dynamic>> records = await dbClient.rawQuery(
        "SELECT * FROM `MessageContent` ${whereStr}ORDER BY `messageId` DESC LIMIT $count");

    records.forEach((element) {
      MessageContent message = MessageContent.fromDbJson(element);
      res.add(message);
    });

    return res;
  }

  Future<MessageContent?> getLastMessage() async {
    List<MessageContent> res = [];
    var dbClient = await db;

    List<Map<String, dynamic>> records = await dbClient.rawQuery(
        "SELECT * FROM `MessageContent` ORDER BY `messageId` DESC LIMIT 1");

    records.forEach((element) {
      log('last message: $element');
      MessageContent message = MessageContent.fromDbJson(element);
      res.add(message);
    });

    return (res.isEmpty) ? null : res.first;
  }

  Future<bool> clearMessagesUnreadStatus(String type, String senderId) async {
    var dbClient = await db;
    Map<String, dynamic> values = {};
    values['unreadCount'] = 0;
    int changedRows = await dbClient.update("Conversation", values,
        where: "senderId = ? AND type = ?", whereArgs: [senderId, type]);
    return true;
  }

  Future<bool> clearMessagesAtStatus(String type, String senderId) async {
    var dbClient = await db;
    Map<String, dynamic> values = {};
    values['atCount'] = 0;
    int changedRows = await dbClient.update("Conversation", values,
        where: "senderId = ? AND type = ?", whereArgs: [senderId, type]);
    return true;
  }

  Future<int> getTotalUnreadCount() async {
    var dbClient = await db;
    List<Map<String, dynamic>> records = await dbClient.rawQuery(
        "SELECT unreadCount FROM `Conversation` WHERE `notify`<>'2' OR `notify` IS NULL");

    var totalCount = 0;
    records.forEach((element) {
      totalCount += element['unreadCount'] as int;
    });
    return totalCount;
  }

  Future<int> getUnreadCount(String type, String senderId) async {
    var dbClient = await db;
    List<Map<String, dynamic>> records = await dbClient.rawQuery(
        "SELECT unreadCount FROM `Conversation` WHERE `senderId`='$senderId' AND `type`='$type'");

    int? unreadCount = Sqflite.firstIntValue(records);
    unreadCount ??= 0;
    return unreadCount;
  }

  /// @param type  conversationType
  Future<MessageContent> insertMessage(
      String type, String senderId, MessageContent message) async {
    message.conversationType = type;
    message.senderId = senderId;

    MessageContent ret = await insertMessageContent(message);
    return ret;
  }

  Future<MessageContent?> getMessageContent(
      String whereStr, List whereArgs) async {
    var dbClient = await db;
    List<Map<String, dynamic>> records = await dbClient.query("MessageContent",
        where: whereStr, whereArgs: whereArgs);
    if (records.isNotEmpty) {
      return MessageContent.fromDbJson(records.first);
    }
    return null;
  }

  Future<bool> updateMessageContent(
      String whereStr, List whereArgs, Map<String, Object?> values) async {
    var dbClient = await db;
    log('update Message content: $values');

    int changedRows = await dbClient.update("MessageContent", values,
        where: whereStr, whereArgs: whereArgs);
    return changedRows > 0;
  }

  Future<MessageContent> insertMessageContent(MessageContent msgContent) async {
    var dbClient = await db;
    try {
      log('insert message targetId: ${msgContent.targetId}');
      msgContent.messageId =
          await dbClient.insert("MessageContent", msgContent.toLocalDbMap());
    } catch (e) {
      log('insert Message error: $e');
    }
    return msgContent;
  }

  Future<bool> deleteMessageContent(String whereStr, List whereArgs) async {
    var dbClient = await db;
    int changedRows = await dbClient.delete("MessageContent",
        where: whereStr, whereArgs: whereArgs);
    return (changedRows == 1) ? true : false;
  }

  Future<void> updateMessageReadStatus(
      String conversationType, String targetId, int timestamp) async {
    var dbClient = await db;
    Map<String, dynamic> values = {};
    values['sentStatus'] = MessageStatus.read;
    int changedRows = await dbClient.update("MessageContent", values,
        where:
            "targetId = ? AND conversationType = ? AND sentTime <= ? AND sentStatus <> ? AND sentStatus <> ? AND sentStatus <> ?",
        whereArgs: [
          targetId,
          conversationType,
          timestamp,
          MessageStatus.delete,
          MessageStatus.read,
          MessageStatus.failed
        ]);
    return;
  }

  Future<bool> updateMessageSentStatus(int messageId, String status) async {
    var dbClient = await db;
    String whereStr = "messageId = ?";
    List whereArgs = [];
    whereArgs.add(messageId);
    Map<String, dynamic> values = {};
    values['sentStatus'] = status;
    int changedRows = await dbClient.update("MessageContent", values,
        where: whereStr, whereArgs: whereArgs);
    return changedRows > 0;
  }

  //关闭
  Future close() async {
    var dbClient = await db;
    return dbClient.close();
  }
}
