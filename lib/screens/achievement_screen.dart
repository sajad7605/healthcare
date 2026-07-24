import 'dart:async';
import 'package:flutter/material.dart' hide Badge;
import '../widgets/squish_pop.dart';
import '../api/healthcare_api.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Badge> _badges = [];
  List<Goal> _goals = [];
  List<Reward> _rewards = [];
  KidStats? _stats;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final child = HealthcareApi.instance.currentChild;
    if (child == null) {
      setState(() {
        _isLoading = false;
        _error = 'لطفاً ابتدا وارد حساب کاربری شوید.';
      });
      return;
    }

    try {
      final results = await Future.wait([
        HealthcareApi.instance.children.getUnlockedBadges(child.id),
        HealthcareApi.instance.children.listChildGoals(child.id),
        HealthcareApi.instance.children.listChildRewards(child.id),
        HealthcareApi.instance.children.getChildStats(child.id),
      ]);

      if (mounted) {
        setState(() {
          _badges = results[0] as List<Badge>;
          _goals = results[1] as List<Goal>;
          _rewards = results[2] as List<Reward>;
          _stats = results[3] as KidStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'خطا در بارگذاری اطلاعات';
        });
      }
    }
  }

  Future<void> _claimReward(Reward reward) async {
    final child = HealthcareApi.instance.currentChild;
    if (child == null) return;

    final currentStars = _stats?.totalStars ?? 0;
    if (currentStars < reward.starsRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'ستاره‌های کافی نداری! ${reward.starsRequired - currentStars} ستاره دیگه لازم داری'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await HealthcareApi.instance.children.claimReward(
        child.id,
        ClaimRewardRequest(rewardId: reward.id),
      );
      setState(() {
        _rewards = _rewards
            .map((r) => r.id == reward.id
                ? Reward(
                    id: r.id,
                    title: r.title,
                    description: r.description,
                    starsRequired: r.starsRequired,
                    status: 'claimed')
                : r)
            .toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('جایزه‌ات ثبت شد! والدینت باید تایید کنن 🎁'),
            backgroundColor: Color(0xFF2ECC71),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF9E6), Color(0xFFFFFDF5)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SquishPopButton(
                        onTap: () => Navigator.of(context).pop(),
                        child: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
                        ),
                      ),
                      const Text(
                        'دستاوردها و جوایز',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                if (_stats != null)
                  _buildStarsSummary(),

                const SizedBox(height: 12),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.emoji_events_rounded, size: 18),
                        text: 'مدال‌ها (${_badges.length})',
                      ),
                      Tab(
                        icon: const Icon(Icons.track_changes_rounded, size: 18),
                        text: 'اهداف (${_goals.length})',
                      ),
                      Tab(
                        icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                        text: 'جوایز (${_rewards.length})',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFFFD700)))
                      : _error != null
                          ? Center(child: Text(_error!))
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildBadgesTab(),
                                _buildGoalsTab(),
                                _buildRewardsTab(),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStarsSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA502)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.star_rounded,
            value: '${_stats!.totalStars}',
            label: 'ستاره',
            color: Colors.white,
          ),
          Container(width: 1, height: 36, color: Colors.white38),
          _StatItem(
            icon: Icons.local_fire_department_rounded,
            value: '${_stats!.currentStreakDays}',
            label: 'روز متوالی',
            color: Colors.white,
          ),
          Container(width: 1, height: 36, color: Colors.white38),
          _StatItem(
            icon: Icons.cleaning_services_rounded,
            value: '${_stats!.brushingCount}',
            label: 'مسواک',
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    if (_badges.isEmpty) {
      return _EmptyState(
        emoji: '🏅',
        message: 'هنوز مدالی نگرفتی!',
        hint: 'با انجام فعالیت‌های دندونی مدال کسب کن',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _badges.length,
      itemBuilder: (context, index) {
        final badge = _badges[index];
        Color badgeColor;
        try {
          badgeColor =
              Color(int.parse(badge.badgeColor.replaceAll('#', '0xFF')));
        } catch (_) {
          badgeColor = const Color(0xFFFFD700);
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: badgeColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFD700),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.description,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF57606F), height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تاریخ: ${badge.unlockedAt.year}/${badge.unlockedAt.month}/${badge.unlockedAt.day}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF95A5A6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalsTab() {
    if (_goals.isEmpty) {
      return _EmptyState(
        emoji: '🎯',
        message: 'هنوز هدفی تعریف نشده!',
        hint: 'از والدینت بخواه هدفی برات بذارن',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        final progress = goal.targetCount > 0
            ? (goal.currentProgress / goal.targetCount).clamp(0.0, 1.0)
            : 0.0;
        final isCompleted = goal.status == 'completed';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isCompleted
                ? Border.all(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.4),
                    width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: (isCompleted
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFF3498DB))
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.track_changes_rounded,
                      color: isCompleted
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFF3498DB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        if (goal.description != null &&
                            goal.description!.isNotEmpty)
                          Text(
                            goal.description!,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF57606F)),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '+${goal.starsReward}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFFE67E22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFF3498DB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${goal.currentProgress}/${goal.targetCount}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              if (isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle_rounded,
                          color: Color(0xFF2ECC71), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'تکمیل شد! ✨',
                        style: TextStyle(
                          color: Color(0xFF2ECC71),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardsTab() {
    final currentStars = _stats?.totalStars ?? 0;

    if (_rewards.isEmpty) {
      return _EmptyState(
        emoji: '🎁',
        message: 'هنوز جایزه‌ای تعریف نشده!',
        hint: 'از والدینت بخواه برات جایزه بذارن',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _rewards.length,
      itemBuilder: (context, index) {
        final reward = _rewards[index];
        final canClaim = reward.status == 'available' &&
            currentStars >= reward.starsRequired;
        final isClaimed =
            reward.status == 'claimed' || reward.status == 'redeemed';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isClaimed
                ? Border.all(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.4),
                    width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isClaimed
                      ? const Color(0xFF2ECC71).withValues(alpha: 0.12)
                      : const Color(0xFFF368E0).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isClaimed
                      ? Icons.check_circle_rounded
                      : Icons.card_giftcard_rounded,
                  color: isClaimed
                      ? const Color(0xFF2ECC71)
                      : const Color(0xFFF368E0),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    if (reward.description != null &&
                        reward.description!.isNotEmpty)
                      Text(
                        reward.description!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF57606F)),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${reward.starsRequired} ستاره',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: currentStars >= reward.starsRequired
                                ? const Color(0xFF27AE60)
                                : Colors.grey,
                          ),
                        ),
                        if (!isClaimed && currentStars < reward.starsRequired)
                          Text(
                            ' (${reward.starsRequired - currentStars} کم داری)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF57606F),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isClaimed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ثبت شد ✓',
                    style: TextStyle(
                      color: Color(0xFF27AE60),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                SquishPopButton(
                  onTap: canClaim ? () => _claimReward(reward) : null,
                  child: AnimatedOpacity(
                    opacity: canClaim ? 1.0 : 0.45,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF368E0), Color(0xFFFF9FF3)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'بگیر!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String message;
  final String hint;

  const _EmptyState({
    required this.emoji,
    required this.message,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: const TextStyle(fontSize: 14, color: Color(0xFF57606F)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
