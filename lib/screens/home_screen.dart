import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'assignments_screen.dart';
import 'attendance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<Widget> _screens = [
    const DashboardScreen(),
    const AssignmentsScreen(),
    const AttendanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.cardLight.withValues(alpha: 0.5)),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                0,
                Icons.dashboard_rounded,
                Icons.dashboard_outlined,
                'Dashboard',
              ),
              _navItem(
                1,
                Icons.assignment_rounded,
                Icons.assignment_outlined,
                'Assignments',
              ),
              _navItem(
                2,
                Icons.event_available_rounded,
                Icons.event_available_outlined,
                'Attendance',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? active : inactive,
              color: isActive ? AppTheme.accent : AppTheme.textSecondary,
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: AppTheme.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../theme/app_theme.dart';
// import '../../services/auth_service.dart';
// import '../services/auth_service.dart';

// // import '../dashboard_screen.dart';
// // import '../assignments_screen.dart';
// // import '../attendance_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
//   int _currentIndex = 0;
//   late AnimationController _navController;

//   final List<Widget> _screens = const [
//     DashboardScreen(),
//     AssignmentsScreen(),
//     AttendanceScreen(),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _navController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//   }

//   @override
//   void dispose() {
//     _navController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 350),
//         switchInCurve: Curves.easeOutCubic,
//         switchOutCurve: Curves.easeInCubic,
//         transitionBuilder: (child, animation) => FadeTransition(
//           opacity: animation,
//           child: SlideTransition(
//             position: Tween<Offset>(
//               begin: const Offset(0, 0.04),
//               end: Offset.zero,
//             ).animate(animation),
//             child: child,
//           ),
//         ),
//         child: KeyedSubtree(
//           key: ValueKey(_currentIndex),
//           child: _screens[_currentIndex],
//         ),
//       ),
//       bottomNavigationBar: _buildBottomNav(),
//     );
//   }

//   Widget _buildBottomNav() {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppTheme.surface,
//         border: Border(
//           top: BorderSide(color: AppTheme.cardLight.withValues(alpha: 0.5)),
//         ),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20),
//         ],
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _navItem(
//                 0,
//                 Icons.dashboard_rounded,
//                 Icons.dashboard_outlined,
//                 'Dashboard',
//               ),
//               _navItem(
//                 1,
//                 Icons.assignment_rounded,
//                 Icons.assignment_outlined,
//                 'Assignments',
//               ),
//               _navItem(
//                 2,
//                 Icons.event_available_rounded,
//                 Icons.event_available_outlined,
//                 'Attendance',
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _navItem(int index, IconData active, IconData inactive, String label) {
//     final isActive = _currentIndex == index;
//     return GestureDetector(
//       onTap: () => setState(() => _currentIndex = index),
//       behavior: HitTestBehavior.opaque,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeOutCubic,
//         padding: EdgeInsets.symmetric(
//           horizontal: isActive ? 20 : 12,
//           vertical: 8,
//         ),
//         decoration: BoxDecoration(
//           color: isActive
//               ? AppTheme.accent.withValues(alpha: 0.15)
//               : Colors.transparent,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               isActive ? active : inactive,
//               color: isActive ? AppTheme.accent : AppTheme.textSecondary,
//               size: 22,
//             ),
//             if (isActive) ...[
//               const SizedBox(width: 6),
//               Text(
//                 label,
//                 style: GoogleFonts.outfit(
//                   color: AppTheme.accent,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
