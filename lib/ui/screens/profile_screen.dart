import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../data/services/api_service.dart';
import 'pin_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  final _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      _uploadImage(File(image.path));
    }
  }

  void _uploadImage(File file) async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    try {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await _apiService.uploadProfilePicBase64(auth.user!.userId!, base64Image);
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
        auth.refreshProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error uploading image')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleUpdatePassword() async {
    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all password fields')));
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    try {
      // Logic from native ProfileActivity.java
      final response = await _apiService.updatePassword(
        auth.user!.userId!,
        _oldPasswordController.text,
        _newPasswordController.text,
      );
      final data = response.data is String ? jsonDecode(response.data) : response.data;

      if (data.toString().toLowerCase().contains('success')) {
        _showSuccessDialog('Success', 'Password updated successfully!');
        _oldPasswordController.clear();
        _newPasswordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update password')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update error')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: user?.profilePic != null && user!.profilePic!.isNotEmpty 
                        ? NetworkImage(user.profilePic!) 
                        : null,
                    child: user?.profilePic == null || user!.profilePic!.isEmpty 
                        ? const Icon(Icons.person, size: 60, color: Colors.grey) 
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.fullName ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Text('Referral Code / QR', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                  const SizedBox(height: 12),
                  QrImageView(
                    data: user?.phone ?? 'HamaldVTU',
                    version: QrVersions.auto,
                    size: 150.0,
                    foregroundColor: AppColors.primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  Text('Code: ${user?.phone ?? ""}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Share.share('Join Hamald VTU and use my referral code: ${user?.phone}');
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('SHARE LINK'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(150, 40)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Align(alignment: Alignment.centerLeft, child: Text('Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Transaction PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PinSetupScreen())),
            ),
            const Divider(),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: Text('Update Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            TextField(controller: _oldPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Old Password')),
            const SizedBox(height: 12),
            TextField(controller: _newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            const SizedBox(height: 24),
            _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _handleUpdatePassword, child: const Text('UPDATE PASSWORD')),

            const SizedBox(height: 40),
            TextButton(
              onPressed: () {
                auth.logout();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              child: const Text('LOGOUT', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
