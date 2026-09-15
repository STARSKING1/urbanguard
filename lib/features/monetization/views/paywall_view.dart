import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../../../core/providers/app_providers.dart';

class PaywallViewScreen extends ConsumerWidget {
  const PaywallViewScreen({super.key});

  Future<void> _presentRevenueCatPaywall(WidgetRef ref) async {
    try {
      PaywallResult result = await RevenueCatUI.presentPaywall();
      if (result == PaywallResult.purchased || result == PaywallResult.restored) {
        ref.read(proStatusProvider.notifier).checkStatus();
      }
    } catch (e) {
      debugPrint("Paywall Launch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(proStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resilience Pro'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
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
                      isPro ? Icons.verified_user : Icons.lock_outline,
                      color: isPro ? Colors.green : const Color(0xFFF59E0B),
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPro ? 'Status: Pro Tier Active' : 'Status: Free Basic Tier',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isPro ? 'All Mesh & Geofencing Unlocked' : 'Upgrade to enable off-grid BLE Mesh',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Pro Tier Capabilities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFeatureTile(Icons.hub, 'Multi-Hop BLE Relay', 'Route emergency signals peer-to-peer across 10+ hops.'),
            _buildFeatureTile(Icons.family_restroom, 'Family Circle Geofencing', 'Real-time alert pings for up to 6 designated family members.'),
            _buildFeatureTile(Icons.psychology, 'Offline AI Triage Protocol', 'Embedded local decision models for disaster response.'),
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
                onPressed: () => _presentRevenueCatPaywall(ref),
                child: Text(
                  isPro ? 'Manage Membership' : 'Upgrade to Resilience Pro',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => ref.read(proStatusProvider.notifier).setMockPro(!isPro),
                child: Text(
                  isPro ? 'Toggle Mock Free Tier' : 'Toggle Mock Pro Tier (Dev Mode)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
