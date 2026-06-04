import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/promo_model.dart';
import '../../data/services/api_service.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../widgets/service_card.dart';
import '../widgets/transaction_item.dart';
import 'airtime_screen.dart';
import 'data_screen.dart';
import 'utility_screen.dart';
import 'cable_screen.dart';
import 'school_screen.dart';
import 'transfer_screen.dart';
import 'transactions_screen.dart';
import 'profile_screen.dart';
import 'membership_screen.dart';
import 'reward_history_screen.dart';
import 'notifications_screen.dart';
import 'support_screen.dart';
import 'pin_setup_screen.dart';
import 'login_screen.dart';
import 'verification_screen.dart';
import '../widgets/fund_account_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<PromoModel> _promos = [];
  String _newsNotice = "";
  final PageController _promoController = PageController();
  int _currentPromoPage = 0;
  Timer? _promoTimer;

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
    _startPromoTimer();
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  void _startPromoTimer() {
    _promoTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_promos.isNotEmpty) {
        if (_currentPromoPage < _promos.length - 1) {
          _currentPromoPage++;
        } else {
          _currentPromoPage = 0;
        }
        if (_promoController.hasClients) {
          _promoController.animateToPage(
            _currentPromoPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> _fetchHomeData() async {
    try {
      final responses = await Future.wait([
        _apiService.getPromos(),
        _apiService.getNews(),
      ]);

      if (mounted) {
        setState(() {
          final promoData = responses[0].data;
          if (promoData is List) {
            _promos = promoData.map((e) => PromoModel.fromJson(e)).toList();
          }

          final newsData = responses[1].data;
          final newsJson = newsData is String ? jsonDecode(newsData) : newsData;
          _newsNotice = newsJson['message'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Home data fetch error: $e");
    }
  }

  void _launchWhatsApp() async {
    final auth = context.read<AuthProvider>();
    final userName = auth.user?.fullName ?? "User";
    final message = "Hello Hamald Concepts, my name is $userName. I need assistance with the Hamald VTU App.";
    final url = "whatsapp://send?phone=2349065057232&text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("WhatsApp not installed")));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      drawer: _buildDrawer(context, authProvider),
      body: RefreshIndicator(
        onRefresh: () => authProvider.refreshProfile(),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, authProvider),
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 20,
                    color: AppColors.primaryBlue,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(context, authProvider),
                      if (_newsNotice.isNotEmpty) _buildNewsMarquee(),
                      _buildPromoSlider(),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Our Services",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildServiceGrid(context),
                      const SizedBox(height: 20),

                      // Recent Transactions Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Transactions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen())),
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  color: AppColors.secondaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Transactions List
                      if (user == null || user.transactions.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                const Text("No recent transactions found", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: user.transactions.take(5).map((t) => TransactionItem(
                              transaction: t,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen())),
                            )).toList(),
                          ),
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _launchWhatsApp,
        backgroundColor: AppColors.successGreen,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Fund'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Support'),
        ],
        onTap: (index) {
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()));
          if (index == 2) showDialog(context: context, builder: (_) => FundAccountDialog(user: authProvider.user));
          if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          if (index == 4) Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
        },
      ),
    );
  }

  Widget _buildNewsMarquee() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                _newsNotice,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primaryBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoSlider() {
    if (_promos.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _promoController,
        itemCount: _promos.length,
        onPageChanged: (index) => setState(() => _currentPromoPage = index),
        itemBuilder: (context, index) {
          final promo = _promos[index];
          return Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: promo.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(color: Colors.grey.shade200),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primaryBlue,
                  child: Center(child: Text(promo.title, style: const TextStyle(color: Colors.white))),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    
    // Determine loyalty color
    Color badgeColor = AppColors.tierBronze;
    if (user?.userLevel?.toLowerCase() == 'silver') badgeColor = AppColors.tierSilver;
    if (user?.userLevel?.toLowerCase() == 'gold') badgeColor = AppColors.tierGold;
    if (user?.userLevel?.toLowerCase() == 'diamond') badgeColor = AppColors.tierDiamond;

    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryBlue,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Good day,",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      if (user?.userLevel != null && user!.userLevel!.toLowerCase() != 'bronze')
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipScreen())),
                          child: Container(
                            margin: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified, color: badgeColor, size: 16),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    auth.user?.fullName?.split(' ')[0] ?? 'User!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: ClipOval(
                    child: auth.user?.profilePic != null && auth.user!.profilePic!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: auth.user!.profilePic!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Icon(Icons.person, color: Colors.white70),
                            errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white70),
                          )
                        : const Icon(Icons.person, color: Colors.white70, size: 30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            // Badge for notifications
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: const Text(
                  '1', // Dynamic count would go here
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.walletStart, AppColors.walletEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (user != null && user.creditLimit > 0)
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardHistoryScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Debt: ₦${Utils.formatCurrency(user.outstandingDebt.toString())}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  auth.balanceHidden ? '₦ ****' : '₦${Utils.formatCurrency(auth.user?.walletBalance ?? '0.00')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => auth.toggleBalanceVisibility(),
                  child: Icon(
                    auth.balanceHidden ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ],
            ),
            if (user != null && user.creditLimit > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Credit Limit: ₦${Utils.formatCurrency(user.creditLimit.toString())}',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                ),
              ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.user?.bankName ?? 'Generating...',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            auth.user?.accountNumber ?? '0000000000',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () {
                              if (auth.user?.accountNumber != null) {
                                Clipboard.setData(ClipboardData(text: auth.user!.accountNumber!));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
                              }
                            },
                            child: const Icon(Icons.copy, color: Colors.white70, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.user?.accountName ?? 'Account Name',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.help_outline, color: Colors.white, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        children: [
          ServiceCard(
            title: 'Airtime',
            icon: Icons.phone_android,
            iconColor: AppColors.tintBlue,
            bgColor: AppColors.bgBlueLight,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AirtimeScreen())),
          ),
          ServiceCard(
            title: 'Data',
            icon: Icons.wifi,
            iconColor: AppColors.tintGreen,
            bgColor: AppColors.bgGreenLight,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataScreen())),
          ),
          ServiceCard(
            title: 'Electricity',
            icon: Icons.lightbulb_outline,
            iconColor: AppColors.tintOrange,
            bgColor: AppColors.bgOrangeLight,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UtilityScreen())),
          ),
          ServiceCard(
            title: 'Cable TV',
            icon: Icons.tv,
            iconColor: AppColors.tintPurple,
            bgColor: AppColors.bgPurpleLight,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CableScreen())),
          ),
          ServiceCard(
            title: 'Exam PIN',
            icon: Icons.school_outlined,
            iconColor: AppColors.tintRed,
            bgColor: AppColors.bgRedLight,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolScreen())),
          ),
          ServiceCard(
            title: 'Transfer',
            icon: Icons.send_to_mobile,
            iconColor: AppColors.tintCyan,
            bgColor: AppColors.bgCyanLight,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen())),
          ),
          ServiceCard(
            title: 'Verify ID',
            icon: Icons.verified_user_outlined,
            iconColor: AppColors.tintBlue,
            bgColor: AppColors.bgBlueLight,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(auth.user?.fullName ?? 'User'),
            accountEmail: Text(auth.user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: auth.user?.profilePic != null ? NetworkImage(auth.user!.profilePic!) : null,
              child: auth.user?.profilePic == null ? const Icon(Icons.person, size: 40, color: AppColors.primaryBlue) : null,
            ),
            decoration: const BoxDecoration(color: AppColors.primaryBlue),
          ),
          _drawerItem(Icons.person_outline, 'My Profile', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          _drawerItem(Icons.star_outline, 'Membership Levels', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipScreen()))),
          _drawerItem(Icons.history, 'Reward History', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardHistoryScreen()))),
          _drawerItem(Icons.security, 'PIN Setup', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PinSetupScreen()))),
          _drawerItem(Icons.support_agent_outlined, 'Support Desk', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()))),
          const Divider(),
          _drawerItem(Icons.logout, 'Logout', () => _showLogoutDialog(context, auth), color: AppColors.errorRed),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Version 1.0.0+18', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }
}
