import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomNavBar extends StatelessWidget {
  final int navIndex;
  final VoidCallback onHome;
  final VoidCallback onExplore;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final String? avatarUrl;

  const BottomNavBar({
    super.key,
    required this.navIndex,
    required this.onHome,
    required this.onExplore,
    required this.onNotifications,
    required this.onProfile,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      height: 42 + MediaQuery.of(context).padding.bottom,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onHome,
              child: SizedBox(
                height: 42 + MediaQuery.of(context).padding.bottom,
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.house,
                      size: 20,
                      color: navIndex == 0
                          ? const Color(0xFF0EA5E9)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onExplore,
              child: SizedBox(
                height: 42 + MediaQuery.of(context).padding.bottom,
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 20,
                      color: navIndex == 1
                          ? const Color(0xFF0EA5E9)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onNotifications,
              child: SizedBox(
                height: 42 + MediaQuery.of(context).padding.bottom,
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.solidBell,
                      size: 20,
                      color: navIndex == 2
                          ? const Color(0xFF0EA5E9)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onProfile,
              child: SizedBox(
                height: 42 + MediaQuery.of(context).padding.bottom,
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: Center(
                    child: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: navIndex == 3
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF0EA5E9),
                                      width: 2.2,
                                    ),
                                  )
                                : null,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(avatarUrl!),
                              backgroundColor: Colors.transparent,
                            ),
                          )
                        : FaIcon(
                            navIndex == 3
                                ? FontAwesomeIcons.solidUser
                                : FontAwesomeIcons.user,
                            size: 16,
                            color: navIndex == 3
                                ? const Color(0xFF0EA5E9)
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
