import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:im_sdk/im/im_client.dart';
import 'package:im_sdk/im/model/message_content.dart';
import 'package:im_sdk/im/util/conversation_data_helper.dart';
import 'package:just_audio/just_audio.dart';

import 'db/db_helper.dart';
import 'protocol/common_define.dart';

class MessageSender {
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;
  final DatabaseHelper _db = DatabaseHelper();

  MessageSender(
      {required this.firebaseFirestore, required this.firebaseStorage});

  UploadTask _uploadImageFile(File image, String fileName) {
    log('try to upload image file');
    Reference reference = firebaseStorage.ref().child('chatImages/$fileName');
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  UploadTask _uploadAudioFile(File audio, String fileName) {
    log('try to upload audio file');
    Reference reference = firebaseStorage.ref().child('audios/$fileName');
    UploadTask uploadTask = reference.putFile(audio);
    return uploadTask;
  }

  void sendTextMessage(
      String content, String receiverId, String conversationType) {
    int timeStamp = DateTime.now().millisecondsSinceEpoch;
    DocumentReference documentReference = firebaseFirestore
        .collection('message')
        .doc(receiverId)
        .collection(receiverId)
        .doc(timeStamp.toString());

    MessageContent message = MessageContent(
        type: MessageType.text.name,
        conversationType: conversationType,
        messageUid: timeStamp,
        user: IMClient.currentUser,
        senderId: IMClient.currentUser.id,
        receiverId: receiverId,
        messageId: 0,
        sentTime: timeStamp,
        targetId: receiverId,
        status: MessageStatus.sent.name,
        content: content);

    firebaseFirestore.runTransaction((transaction) async {
      transaction.set(
        documentReference,
        message.toFirebaseMap(),
      );
    });
    _db.insertMessageContent(message);
  }

  void sendImageMessage(
      File file, String receiverId, String conversationType) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = _uploadImageFile(file, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();
      log('get image url is: $imageUrl');
      int timeStamp = DateTime.now().millisecondsSinceEpoch;
      DocumentReference documentReference = firebaseFirestore
          .collection('message')
          .doc(receiverId)
          .collection(receiverId)
          .doc(timeStamp.toString());

      MessageContent message = MessageContent(
          type: MessageType.image.name,
          conversationType: conversationType,
          messageUid: timeStamp,
          user: IMClient.currentUser,
          senderId: IMClient.currentUser.id,
          receiverId: receiverId,
          messageId: 0,
          sentTime: timeStamp,
          status: MessageStatus.sent.name,
          targetId: receiverId,
          content: 'image',
          imageUrl: imageUrl);

      await firebaseFirestore.runTransaction((transaction) async {
        transaction.set(
          documentReference,
          message.toFirebaseMap(),
        );
      });
      log('push message to cloud done');
      await _db.insertMessageContent(message);
      await ConversationDataHelper.updateOrInsertConversation(
          message, message.senderId, firebaseFirestore);

      log('insert to local db done');
      // notify the listener to update UI
      IMClient.messageStreamController.add(message);
    } on FirebaseException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void sendAudioMessage(
      File file, String receiverId, String conversationType) async {
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.mp3';
    UploadTask uploadTask = _uploadAudioFile(file, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      String audioUrl = await snapshot.ref.getDownloadURL();
      log('get audio url is: $audioUrl');
      final player = AudioPlayer();
      Duration? duration = await player.setUrl(audioUrl);
      if (duration == null) return;
      log('get audio duration is: ${duration.inSeconds} seconds');
      int timeStamp = DateTime.now().millisecondsSinceEpoch;
      DocumentReference documentReference = firebaseFirestore
          .collection('message')
          .doc(receiverId)
          .collection(receiverId)
          .doc(timeStamp.toString());

      MessageContent message = MessageContent(
          type: MessageType.audio.name,
          conversationType: conversationType,
          messageUid: timeStamp,
          user: IMClient.currentUser,
          senderId: IMClient.currentUser.id,
          receiverId: receiverId,
          messageId: 0,
          sentTime: timeStamp,
          status: MessageStatus.sent.name,
          targetId: receiverId,
          content: 'audio',
          audioUrl: audioUrl,
          duration: duration.inSeconds);

      await firebaseFirestore.runTransaction((transaction) async {
        transaction.set(
          documentReference,
          message.toFirebaseMap(),
        );
      });
      log('push message to cloud done');
      await _db.insertMessageContent(message);
      await ConversationDataHelper.updateOrInsertConversation(
          message, message.senderId, firebaseFirestore);

      log('insert to local db done');
      // notify the listener to update UI
      IMClient.messageStreamController.add(message);
    } on FirebaseException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }
}
