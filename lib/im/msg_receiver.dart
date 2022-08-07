import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:im_sdk/im/im_client.dart';
import 'package:im_sdk/im/model/message_content.dart';
import 'db/db_helper.dart';
import 'util/conversation_data_helper.dart';

class MessageReceiver {
  final FirebaseFirestore firebaseFirestore;
  final DatabaseHelper _db = DatabaseHelper();

  MessageReceiver({required this.firebaseFirestore});

  void startListen(String userId) async {
    MessageContent? lastItem = await _db.getLastMessage();
    int timeStamp = DateTime.now().millisecondsSinceEpoch;
    if (lastItem != null) timeStamp = lastItem.sentTime;
    log('start listen incoming message timeStamp > $timeStamp');
    firebaseFirestore
        .collection('message')
        .doc(userId)
        .collection(userId)
        .where('sentTime', isGreaterThan: timeStamp)
        .orderBy('sentTime', descending: true)
        .limit(1)
        .snapshots()
        .listen((event) {
      List<DocumentSnapshot> items = event.docs;
      if (items.isNotEmpty) {
        items.forEach((element) async {
          MessageContent item = MessageContent.fromFirebaseJson(
              element.data() as Map<String, dynamic>);
          _handleNewMessage(item);
        });
      }
    });
  }

  void _handleNewMessage(MessageContent message) async {
    log("receive new message: ${message.content}");
    await _db.insertMessageContent(message);
    await ConversationDataHelper.updateOrInsertConversation(
        message, message.senderId, firebaseFirestore);
    IMClient.messageStreamController.add(message);
  }
}
