import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:near_share/features/auth/presentation/providers/auth_provider.dart';
import 'package:near_share/features/home/presentation/pages/home_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'NearShare',
    'My Rentals',
    'My Items',
    'Settings',
  ];

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return const HomePage();
      case 1:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(child: Text('My Rentals')),
        );
      case 2:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(child: Text('My Product Management')),
        );
      case 3:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(child: Text('App Settings')),
        );
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),
              ),
            ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Rentals',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Items',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                user?.displayName ?? 'User Name',
                style: theme.textTheme.headlineMedium,
              ),
              Text(user?.email ?? 'user@example.com'),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    authProvider.signOut();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
