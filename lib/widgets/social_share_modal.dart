import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum ShareType { clinicalCard, examReport, testHistory }

class SocialShareModal extends StatefulWidget {
  final String title;
  final String subtitle;
  final String shareText;
  final Widget? cardPreview;
  final Future<void> Function()? onShareImage;
  final ShareType type;

  const SocialShareModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.shareText,
    this.cardPreview,
    this.onShareImage,
    this.type = ShareType.clinicalCard,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String shareText,
    Widget? cardPreview,
    Future<void> Function()? onShareImage,
    ShareType type = ShareType.clinicalCard,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SocialShareModal(
        title: title,
        subtitle: subtitle,
        shareText: shareText,
        cardPreview: cardPreview,
        onShareImage: onShareImage,
        type: type,
      ),
    );
  }

  @override
  State<SocialShareModal> createState() => _SocialShareModalState();
}

class _SocialShareModalState extends State<SocialShareModal> {
  bool _isSharingImage = false;

  Future<void> _shareDirectPlatform(String platform) async {
    final encodedText = Uri.encodeComponent(widget.shareText);
    String url = '';

    switch (platform) {
      case 'whatsapp':
        url = 'whatsapp://send?text=$encodedText';
        break;
      case 'x':
        url = 'https://twitter.com/intent/tweet?text=$encodedText';
        break;
      case 'telegram':
        url = 'https://t.me/share/url?text=$encodedText';
        break;
      case 'linkedin':
        url = 'https://www.linkedin.com/sharing/share-offsite/?text=$encodedText';
        break;
    }

    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      try {
        final canLaunch = await canLaunchUrl(uri);
        if (canLaunch) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint('Direct share launch error: $e');
      }
    }

    // Fallback to standard share sheet
    SharePlus.instance.share(ShareParams(text: widget.shareText));
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: widget.shareText));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.greenAccent),
              SizedBox(width: 8),
              Text('Summary copied to clipboard!'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pill drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title & Subtitle
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, color: Colors.cyan, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: textColor.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Live Card Visual Preview (if provided)
            if (widget.cardPreview != null) ...[
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: widget.cardPreview!,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Text Summary Snippet Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes, size: 18, color: Colors.blueAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.shareText.replaceAll('\n', ' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.8),
                        height: 1.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy text',
                    onPressed: _copyText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Social Platform Action Buttons
            Text(
              'SHARE DIRECTLY TO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: textColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialIcon(
                  label: 'WhatsApp',
                  icon: Icons.chat,
                  color: const Color(0xFF25D366),
                  onTap: () => _shareDirectPlatform('whatsapp'),
                ),
                _buildSocialIcon(
                  label: 'X / Twitter',
                  icon: Icons.alternate_email,
                  color: isDark ? Colors.white : Colors.black,
                  onTap: () => _shareDirectPlatform('x'),
                ),
                _buildSocialIcon(
                  label: 'Telegram',
                  icon: Icons.send,
                  color: const Color(0xFF229ED9),
                  onTap: () => _shareDirectPlatform('telegram'),
                ),
                _buildSocialIcon(
                  label: 'LinkedIn',
                  icon: Icons.work,
                  color: const Color(0xFF0077B5),
                  onTap: () => _shareDirectPlatform('linkedin'),
                ),
                _buildSocialIcon(
                  label: 'Copy',
                  icon: Icons.copy_all,
                  color: Colors.deepPurpleAccent,
                  onTap: _copyText,
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Primary Action Buttons
            if (widget.onShareImage != null) ...[
              ElevatedButton.icon(
                onPressed: _isSharingImage
                    ? null
                    : () async {
                        setState(() => _isSharingImage = true);
                        try {
                          await widget.onShareImage!();
                        } finally {
                          if (mounted) setState(() => _isSharingImage = false);
                        }
                      },
                icon: _isSharingImage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.image, color: Colors.white),
                label: Text(
                  _isSharingImage ? 'Generating Graphic...' : 'Share Graphic Card (PNG)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
              const SizedBox(height: 10),
            ],

            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                SharePlus.instance.share(ShareParams(text: widget.shareText));
              },
              icon: const Icon(Icons.share),
              label: const Text(
                'More Share Options / All Apps',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
