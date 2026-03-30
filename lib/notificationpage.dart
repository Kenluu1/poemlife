import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header "Notifications"
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
            child: Text(
              "Notifications",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: isLoading ? _buildLoading() : _buildEmptyState(),
          ),
        ],
      ),
    );
  }


  Widget _buildLoading() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(0xFF993B3B), shape: BoxShape.circle)),
          SizedBox(width: 5),
          Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(0xFFF29C38), shape: BoxShape.circle)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/notificationerror.png',
            width: 250,
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.notifications_off_outlined,
              size: 100,
              color: Colors.grey.shade300,
            ),
          ),
          SizedBox(height: 20),

          Text(
            "No Notifications yet",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "Return here for updates on activities and new poems",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
            ),
          ),

          SizedBox(height: 100),
        ],
      ),
    );
  }
}