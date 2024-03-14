import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loading_circle.dart';
import 'top_card.dart';
import 'transactions.dart';
import 'plus_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _textControllerAmount = TextEditingController();
  final _textControllerItem = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isIncome = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double totalBalance = 0;
  double totalIncome = 0;
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _updateTotals();
  }

  void signUserOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AuthPage()),
      (route) => false,
    );
  }

  void _enterTransaction() async {
    User? user = _auth.currentUser;

    if (user != null) {
      String uid = user.uid;

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return AlertDialog(
                title: Text(' NEW  TRANSACTION '),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text('Expense'),
                          Switch(
                            value: _isIncome,
                            onChanged: (newValue) {
                              setState(() {
                                _isIncome = newValue;
                              });
                            },
                          ),
                          Text('Income'),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Form(
                              key: _formKey,
                              child: TextFormField(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Amount?',
                                ),
                                validator: (text) {
                                  if (text == null || text.isEmpty) {
                                    return 'Enter an amount';
                                  }
                                  return null;
                                },
                                controller: _textControllerAmount,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'For what?',
                              ),
                              controller: _textControllerItem,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  MaterialButton(
                    color: Colors.grey[600],
                    child:
                        Text('Cancel', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  MaterialButton(
                    color: Colors.grey[600],
                    child: Text('Enter', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _addTransaction(uid);
                        Navigator.of(context).pop();
                      }
                    },
                  )
                ],
              );
            },
          );
        },
      );
    }
  }

  Future<void> _addTransaction(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .add({
      'item': _textControllerItem.text,
      'amount': _textControllerAmount.text,
      'isIncome': _isIncome,
    });
    _updateTotals();
  }

  void _updateTotals() async {
    User? user = _auth.currentUser;

    if (user != null) {
      String uid = user.uid;

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .get();

      totalExpense = 0;
      totalIncome = 0;

      querySnapshot.docs.forEach((doc) {
        var transaction = doc.data() as Map<String, dynamic>;
        double amount = double.parse(transaction['amount']);

        if (transaction['isIncome']) {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
      });

      setState(() {
        totalBalance = totalIncome - totalExpense;
      });
    }
  }

  Future<void> _deleteTransaction(String uid, String transactionId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(transactionId)
        .delete();

    _updateTotals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        actions: [
          IconButton(
            onPressed: () => signUserOut(context),
            icon: Icon(Icons.logout, color: Colors.black),
          ),
        ],
        title: Text(
          'F I N P A L',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[300],
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 30,
            ),
            TopNeuCard(
              balance: totalBalance.toString(),
              income: totalIncome.toString(),
              expense: totalExpense.toString(),
            ),
            SizedBox(
              height: 15,
            ),
            Expanded(
              child: Container(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .doc(_auth.currentUser?.uid)
                      .collection('transactions')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return LoadingCircle();
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    var transactionDocs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: transactionDocs.length,
                      itemBuilder: (context, index) {
                        var transaction = transactionDocs[index].data()
                            as Map<String, dynamic>;

                        return Dismissible(
                          key: Key(transactionDocs[index].id),
                          background: Container(
                            color: Colors.red,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          onDismissed: (direction) async {
                            await _deleteTransaction(
                                _auth.currentUser?.uid ?? '',
                                transactionDocs[index].id);
                          },
                          child: MyTransaction(
                            transactionId: transactionDocs[index].id,
                            transactionName: transaction['item'],
                            money: transaction['amount'],
                            expenseOrIncome:
                                transaction['isIncome'] ? 'Income' : 'Expense',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            PlusButton(
              function: _enterTransaction,
            ),
          ],
        ),
      ),
    );
  }
}

class MyTransaction extends StatelessWidget {
  final String transactionId;
  final String transactionName;
  final String money;
  final String expenseOrIncome;

  MyTransaction({
    required this.transactionId,
    required this.transactionName,
    required this.money,
    required this.expenseOrIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(15),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.grey[500]),
                    child: Center(
                      child: Icon(
                        Icons.currency_rupee_sharp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(transactionName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      )),
                ],
              ),
              Text(
                (expenseOrIncome == 'Expense' ? '-' : '+') + '\₹' + money,
                style: TextStyle(
                  //fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color:
                      expenseOrIncome == 'Expense' ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ... (other parts of the code)
