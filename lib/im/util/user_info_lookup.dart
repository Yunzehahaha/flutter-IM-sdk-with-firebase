import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:im_sdk/im/model/send_user.dart';

class UserInfoLookup {
  final FirebaseFirestore firebaseFirestore;
  UserInfoLookup(this.firebaseFirestore);

  Future<SendUser?> getUser(String uid) async {
    Query query =
        firebaseFirestore.collection('users').where('id', isEqualTo: uid);
    QuerySnapshot userSnapshot = await query.get();
    List<DocumentSnapshot> items = userSnapshot.docs;
    log("fetch ${items.length} user's info");
    if (items.isNotEmpty) {
      SendUser item =
          SendUser.fromFirebaseUser(items.first.data() as Map<String, dynamic>);
      return item;
    } else {
      return null;
    }
  }
}
