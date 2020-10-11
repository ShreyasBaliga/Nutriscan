import 'package:cloud_firestore/cloud_firestore.dart';

class Record {
  final int weight;
  final int height;
  final int maxCal;
  final int curCal;

  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['weight'] != null),
        assert(map['height'] != null),
        assert(map['caloriesAllowed'] != null),
        assert(map['currentCalories'] != null),
        weight = map['weight'],
        height = map['height'],
        maxCal = map['caloriesAllowed'],
        curCal = map['currentCalories'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);
}
