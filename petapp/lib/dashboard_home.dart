import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'find_disease_page.dart'; // Import the FindDiseasePage

class DashboardHome extends StatefulWidget {
  final String? userName;
  final String? role;
  const DashboardHome({super.key, this.userName, this.role});

  @override
  _DashboardHomeState createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> with TickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _cardAnim;

  @override
  void initState() {
    super.initState();
    _cardAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() {
    _cardAnim.dispose();
    super.dispose();
  }

  Widget _buildHome(User? user) {
    const bottomBarHeight = 64.0;
    final bottomPad = MediaQuery.of(context).padding.bottom + bottomBarHeight + 12.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 12, 14, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hello, ${widget.userName ?? user?.email ?? 'Pet Lover'}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 86,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFeatureCardCompact('Adopt a Pet', Icons.pets, Colors.pinkAccent),
                _buildFeatureCardCompact('Daily Care', Icons.calendar_today, Colors.orangeAccent),
                _buildFeatureCardCompact('Community', Icons.forum, Colors.lightBlue),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: FadeTransition(
              opacity: _cardAnim,
              child: LayoutBuilder(builder: (context, constraints) {
                final cross = constraints.maxWidth > 700 ? 3 : 2;
                return GridView.count(
                  crossAxisCount: cross,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.92,
                  children: List.generate(4, (i) => _smallStatCard(i)),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCardCompact(String title, IconData icon, Color color) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.95), color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.22), blurRadius: 6, offset: const Offset(0,3))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const Spacer(),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _smallStatCard(int i) {
    final titles = ['My Pets', 'Reminders', 'Tips', 'Find Disease'];
    final colors = [Colors.teal, Colors.deepPurple, Colors.indigo, Colors.deepOrange];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () {
          if (i == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FindDiseasePage()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open ${titles[i]}')));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 14, backgroundColor: colors[i].withOpacity(0.95), child: Icon(Icons.circle, color: Colors.white, size: 12)),
              const SizedBox(height: 6),
              Text(titles[i], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const Spacer(),
              Text('${(i+1)*3} items', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    Widget body;
    switch (_index) {
      case 0:
        body = _buildHome(user);
        break;
      default:
        body = _buildHome(user);
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.teal.shade600, Colors.deepPurple.shade400]),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Colors.pinkAccent.shade200, Colors.orangeAccent.shade200]),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0,3))],
              ),
              child: const Center(child: Icon(Icons.pets, color: Colors.white, size: 20)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PetBondhuBD', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('Friends for your pets', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ],
        ),
      ),
      extendBody: true,
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: body),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: SizedBox(
          width: 46,
          height: 46,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            tooltip: 'Find Disease',
            child: const Icon(Icons.local_hospital, size: 18),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FindDiseasePage()),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        elevation: 12,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.deepPurple.shade400],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navItem(Icons.home, 'Home', 0),
                _navItem(Icons.local_hospital, 'Find Disease', 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx) {
    final selected = _index == idx;
    return InkWell(
      onTap: () => setState(() => _index = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.white70, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
