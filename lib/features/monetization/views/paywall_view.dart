import 'package:flutter/material.dart';
import '../../../core/services/revenuecat_service.dart';

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
    final active = await RevenueCatService.isProUser();
    if (mounted) {
      setState(() {
        _isPro = active;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resilience Pro'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.security, size: 64, color: Color(0xFF38BDF8)),
                  const SizedBox(height: 16),
                  Text(
                    _isPro ? 'Pro Subscription Active' : 'Upgrade to UrbanGuard Pro',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPro
                        ? 'You have unlocked offline mesh relaying and unlimited radius alerts.'
                        : 'Get offline mesh routing, custom hazard radius zones, and multi-peer priority relays.',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureRow(Icons.wifi_off, 'Offline Peer Relay', 'Route alerts without cellular service'),
                  const SizedBox(height: 16),
                  _buildFeatureRow(Icons.radar, 'Unlimited Zone Alerts', 'Set custom perimeter radii up to 50km'),
                  const Spacer(),
                  if (!_isPro)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {},
                        child: const Text('Subscribe Now', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
