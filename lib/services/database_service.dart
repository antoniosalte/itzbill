import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:itzbill/models/bill.dart';
import 'package:itzbill/models/expense.dart';
import 'package:itzbill/models/rate.dart';
import 'package:itzbill/models/pool.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Pool>> loadPools(String uid) async {
    List<Pool> pools = [];

    QuerySnapshot query = await _firestore
        .collection('pool')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt')
        .get();

    for (DocumentSnapshot document in query.docs) {
      Map data = document.data() as Map<String, dynamic>;

      List<Expense> initialExpenses = [];
      List<Expense> finalExpenses = [];

      List<dynamic> initialExpensesMap = data['initialExpenses'];
      List<dynamic> finalExpensesMap = data['finalExpenses'];

      initialExpensesMap.forEach((element) {
        Expense expense = Expense.fromMap(element);
        initialExpenses.add(expense);
      });

      finalExpensesMap.forEach((element) {
        Expense expense = Expense.fromMap(element);
        finalExpenses.add(expense);
      });

      Rate rate = Rate.fromMap(data['rate']);
      Rate tea = Rate.fromMap(data['tea']);

      Pool pool = Pool.fromFirestore(
        data['id'],
        data['userId'],
        data['name'],
        data['createdAt'].toDate(),
        data['discountDate'].toDate(),
        rate,
        tea,
        data['tcea'],
        data['receivedTotal'],
        data['currency'],
        initialExpenses,
        finalExpenses,
      );

      pools.add(pool);
    }

    return pools;
  }

  Future<Pool> createPool(
    String userId,
    String name,
    DateTime discountDate,
    Rate rate,
    String currency,
    List<Expense> initialExpenses,
    List<Expense> finalExpenses,
  ) async {
    DocumentReference documentReference = _firestore.collection('pool').doc();

    Pool pool = Pool.createToFirestore(
      documentReference.id,
      userId,
      name,
      discountDate,
      rate,
      currency,
      initialExpenses,
      finalExpenses,
    );

    await documentReference.set(pool.toFirestore());

    return pool;
  }

  Future<void> updatePool(
      String poolId, double tcea, double receivedTotal) async {
    await _firestore.collection('pool').doc(poolId).update({
      'tcea': tcea,
      'receivedTotal': receivedTotal,
    });
  }

  Future<void> deletePool(String poolId) async {
    await _firestore.collection('pool').doc(poolId).delete();
  }

  Future<List<Bill>> loadBills(String poolId) async {
    List<Bill> bills = [];

    QuerySnapshot query = await _firestore
        .collection('bill')
        .where('poolId', isEqualTo: poolId)
        .orderBy('createdAt')
        .get();

    for (DocumentSnapshot document in query.docs) {
      Map data = document.data() as Map<String, dynamic>;
      bills.add(Bill.fromMap(data));
    }

    return bills;
  }

  Future<Bill> createBill(
    String poolId,
    String userId,
    DateTime discountDate,
    DateTime turnDate,
    DateTime dueDate,
    double nominalValue,
    double retention,
    List<Expense> initialExpenses,
    List<Expense> finalExpenses,
    Rate tea,
  ) async {
    DocumentReference documentReference = _firestore.collection('bill').doc();

    Bill bill = Bill.createToFirestore(
      documentReference.id,
      poolId,
      userId,
      discountDate,
      turnDate,
      dueDate,
      nominalValue,
      retention,
      initialExpenses,
      finalExpenses,
      tea,
    );

    await documentReference.set(bill.toFirestore());

    return bill;
  }

  Future<void> deleteBill(String billId) async {
    await _firestore.collection('bill').doc(billId).delete();
  }
}
