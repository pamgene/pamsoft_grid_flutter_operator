import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pamsoft_grid_flutter_operator/core/theme/app_colors.dart';
import 'package:pamsoft_grid_flutter_operator/core/theme/app_spacing.dart';
import 'package:pamsoft_grid_flutter_operator/core/theme/app_text_styles.dart';
import 'left_panel_section.dart';

/// INFO section for the left panel.
///
/// Required for all Tercen apps, displays:
/// - GitHub link with version/commit
class InfoSection extends StatelessWidget {
  final String gitRepo;
  final String gitVersion;

  const InfoSection({
    super.key,
    required this.gitRepo,
    required this.gitVersion,
  });

  Future<void> _launchGitHub() async {
    final uri = Uri.parse(gitRepo);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LeftPanelSection(
      icon: FontAwesomeIcons.circleInfo,
      label: 'Info',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (gitVersion.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'GitHub:',
                  style: AppTextStyles.label,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: InkWell(
                    onTap: _launchGitHub,
                    child: Text(
                      gitVersion,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Development build',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
