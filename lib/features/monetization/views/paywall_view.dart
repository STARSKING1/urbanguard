import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PaywallViewScreen extends StatefulWidget {
  const PaywallViewScreen({super.key});

  @override
  State<PaywallViewScreen> createState() => _PaywallViewScreenState();
}

class _PaywallViewScreenState extends State<PaywallViewScreen> {
  bool _isPro = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkEntitlements();
  }

  Future<void> _checkEntitlements() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      setState(() {
        _isPro = customerInfo.entitlements.all['pro_access']?.isActive ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _presentPaywall() async {
    try {
      PaywallResult result = await RevenueCatUI.presentPaywall();
      if (result == PaywallResult.purchased || result == PaywallResult.restored) {
        _checkEntitlements();
      }
    } catch (e) {
      debugPrint("Paywall UI Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resilience Pro & Family Circle'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            _isPro ? Icons.verified_user : Icons.lock_outline,
                            color: _isPro ? Colors.green : const Color(0xFFF59E0B),
                            size: 36,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isPro ? 'Status: Pro Active' : 'Status: Basic Tier',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _isPro
                                    ? 'Full Mesh & Family Circle Unlocked'
                                    : 'Upgrade to enable BLE Mesh & Family Tracking',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Pro Resilience Features', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const FeatureRow(icon: Icons.hub, title: 'Multi-Hop BLE Mesh Relay', subtitle: 'Send distress signals off-grid across devices.'),
                  const FeatureRow(icon: Icons.family_restroom, title: 'Family Circle Geofencing', subtitle: 'Live location tracking & alert pings for up to 6 members.'),
                  const FeatureRow(icon: Icons.psychology, title: 'AI Disaster Triage Assistant', subtitle: 'Offline medical & survival protocol guidance.'),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _presentPaywall,
                      child: Text(
                        _isPro ? 'Manage Membership' : 'Upgrade to Resilience Pro',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureRow({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
