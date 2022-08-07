import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:im_sdk/im/model/conversation.dart';
import 'package:im_sdk/im/model/message_content.dart';
import 'package:im_sdk/im/msg_receiver.dart';
import 'package:im_sdk/im/msg_sender.dart';

import 'db/db_helper.dart';
import 'model/send_user.dart';
import 'protocol/common_define.dart';

class IMClient {
  static late SendUser currentUser;
  // app need to listen this stream to get incomming message notifacation
  static StreamController<MessageContent> messageStreamController =
      StreamController<MessageContent>.broadcast();

  static late MessageReceiver _messageReceiver;
  static late MessageSender _messageSender;
  static final DatabaseHelper _db = DatabaseHelper();

  static void initIm(FirebaseStorage firebaseStorage,
      FirebaseFirestore firebaseFirestore, SendUser user) {
    currentUser = user;
    _messageReceiver = MessageReceiver(firebaseFirestore: firebaseFirestore);
    _messageSender = MessageSender(
        firebaseFirestore: firebaseFirestore, firebaseStorage: firebaseStorage);
    log("init IM done...");
    startListen();
  }

  static void startListen() {
    _messageReceiver.startListen(currentUser.id);
    log("start listen IM ...");
  }

  static void sendTextMessage(
      String content, String receiverId, ConversationType conversationType) {
    _messageSender.sendTextMessage(content, receiverId, conversationType.name);
  }

  static void sendImageMessage(
      File image, String receiverId, ConversationType conversationType) {
    _messageSender.sendImageMessage(image, receiverId, conversationType.name);
  }

  static void sendAudioMessage(
      File audio, String receiverId, ConversationType conversationType) {
    _messageSender.sendAudioMessage(audio, receiverId, conversationType.name);
  }

  static Future<List<Conversation>> getConversationList() async {
    log('try to get converstaion list');
    return await _db.getConversationList();
  }

  static Future<List<MessageContent>> getHistoryMessages(
    String type,
    String targetId, [
    int oldestMessageId = 0,
    int count = 20,
  ]) async {
    log('getHistoryMessages type=$type, targetId=$targetId, oldestMessageId=$oldestMessageId, count=$count');
    if (oldestMessageId == null || oldestMessageId < 0) {
      oldestMessageId = 0;
    }
    return await _db.getHistoryMessages(type, targetId, oldestMessageId, count);
  }
}
