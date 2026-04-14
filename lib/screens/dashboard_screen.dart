import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mifinper/models/account_data.dart';
import 'package:mifinper/screens/list_accounts_screen.dart';
import 'package:mifinper/screens/transactions/another_transaction.dart';
import 'package:mifinper/services/api_service.dart';
import 'package:mifinper/services/utils_functions.dart';
import 'package:mifinper/widgets/custom_app_bar.dart';
import 'package:mifinper/widgets/main_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  List<dynamic> _dashboardInformation = [];
  bool _isFetchingDashboardInformation = true;
  String? _selectedProfile;

  List<dynamic> _summaryMonths = [];
  bool _isFetchingSummary = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 &&
        _selectedProfile != null &&
        _summaryMonths.isEmpty &&
        !_isFetchingSummary) {
      _loadSummaryMonths(_selectedProfile!);
    }
  }

  Future<void> _loadSummaryMonths(String profileId) async {
    setState(() => _isFetchingSummary = true);
    try {
      final data = await _apiService.fetchSummaryMonths(profileId);
      if (mounted) {
        setState(() => _summaryMonths = data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingSummary = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: _buildAppBar(),
      child: _selectedProfile == null
          ? const Center(
              child: Text('Please select a profile to see the accounts.'),
            )
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                    Tab(icon: Icon(Icons.bar_chart), text: 'Monthly Summary'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDashboardTab(),
                      _buildSummaryTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      onDashboardInformationChanged: (dashboardInformation) {
        if (mounted) {
          setState(() {
            _dashboardInformation = dashboardInformation;
          });
        }
      },
      onFetchingDashboardInformationChanged: (isFetching) {
        if (mounted) {
          setState(() {
            _isFetchingDashboardInformation = isFetching;
          });
        }
      },
      onSelectedProfileChanged: (profileId) {
        if (mounted) {
          setState(() {
            _selectedProfile = profileId;
            _summaryMonths = [];
          });
          if (profileId != null && _tabController.index == 1) {
            _loadSummaryMonths(profileId);
          }
        }
      },
    );
  }

  // ── Tab 1: existing dashboard ─────────────────────────────────────────────

  Widget _buildDashboardTab() {
    if (_isFetchingDashboardInformation) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_dashboardInformation.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No dashboardInformation yet.'),
            TextButton(
              child: const Text('You can init setting the cash'),
              onPressed: () => Navigator.pushNamed(context, '/cash'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Here is your resume:',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AnotherTransaction()),
                ),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return GridView.builder(
                  itemCount: _dashboardInformation.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3.5,
                  ),
                  itemBuilder: (context, index) {
                    final account =
                        Utils().setAccountData(_dashboardInformation[index]);
                    return _buildAccountCard(account);
                  },
                );
              } else {
                return ListView.builder(
                  itemCount: _dashboardInformation.length,
                  itemBuilder: (context, index) {
                    final account =
                        Utils().setAccountData(_dashboardInformation[index]);
                    return _buildAccountCard(account);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(AccountData account) {
    final balance = num.tryParse(account.balance.toString()) ?? 0;
    final bool isPositive = Utils().checkPositiveBalance(account, balance);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isPositive ? Colors.blue.shade100 : Colors.red.shade100,
          child: Icon(
            balance >= 0
                ? Icons.account_balance_wallet
                : Icons.warning_amber_rounded,
            color: isPositive ? Colors.blue : Colors.red,
          ),
        ),
        title: Text(
          account.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(account.code),
            const SizedBox(height: 5),
            Text(
              'Value: ${Utils().formatCurrency(account, balance)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isPositive ? Colors.blue.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ),
        trailing: TextButton(
          child: const Text('Edit'),
          onPressed: () => _navigateToListChildAccount(account),
        ),
      ),
    );
  }

  void _navigateToListChildAccount(AccountData account) {
    if (_selectedProfile != null) {
      String parentCodeToPass = '${account.code}.';
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ListAccountsScreen(
                  accountParentCode: parentCodeToPass,
                  isOnlyParent: true,
                  isOnlyFinal: false,
                )),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile first.')),
      );
    }
  }

  // ── Tab 2: monthly summary chart ──────────────────────────────────────────

  Widget _buildSummaryTab() {
    if (_isFetchingSummary) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_summaryMonths.isEmpty) {
      return Center(
        child: TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Load monthly summary'),
          onPressed: () => _loadSummaryMonths(_selectedProfile!),
        ),
      );
    }

    // Sort by year+month ascending
    final sorted = List<dynamic>.from(_summaryMonths)
      ..sort((a, b) {
        final aKey = '${a['year']}${a['month']}';
        final bKey = '${b['year']}${b['month']}';
        return aKey.compareTo(bKey);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegend(),
          const SizedBox(height: 16),
          Text('Result per month',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: _buildBarChart(sorted, isResult: true),
          ),
          const SizedBox(height: 32),
          Text('Balance per month',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: _buildBarChart(sorted, isResult: false),
          ),
          const SizedBox(height: 16),
          _buildSummaryTable(sorted),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      children: [
        _legendItem(Colors.teal, 'Positive'),
        _legendItem(Colors.red.shade400, 'Negative'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBarChart(List<dynamic> data, {required bool isResult}) {
    final barGroups = data.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final raw = (item[isResult ? 'result' : 'balance'] as num).toDouble();
      final color = raw >= 0 ? Colors.teal : Colors.red.shade400;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: raw,
            color: color,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    final values = data
        .map((e) => (e[isResult ? 'result' : 'balance'] as num).toDouble())
        .toList();
    final maxAbs = values.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
    final padding = maxAbs * 0.2;

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        minY: values.any((v) => v < 0) ? -(maxAbs + padding) : 0,
        maxY: maxAbs + padding,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (value, meta) => Text(
                _formatAxis(value),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                final item = data[idx];
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${item['month']}/${item['year']}',
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = data[group.x];
              return BarTooltipItem(
                '${item['month']}/${item['year']}\n${_formatValue(rod.toY)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTable(List<dynamic> data) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(1),
        },
        border: TableBorder.all(
            color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Colors.black87),
            children: const [
              _TableCell('Month', isHeader: true),
              _TableCell('Result', isHeader: true),
              _TableCell('Balance', isHeader: true),
              _TableCell('Status', isHeader: true),
            ],
          ),
          ...data.map((item) {
            final result = (item['result'] as num).toDouble();
            final balance = (item['balance'] as num).toDouble();
            final status = item['status'] as bool;
            return TableRow(
              children: [
                _TableCell('${item['month']}/${item['year']}'),
                _TableCell(
                  _formatValue(result),
                  color: result >= 0 ? Colors.teal : Colors.red.shade600,
                ),
                _TableCell(
                  _formatValue(balance),
                  color: balance >= 0 ? Colors.teal : Colors.red.shade600,
                ),
                _TableCell(
                  status ? 'Closed' : 'Open',
                  color: status ? Colors.grey : Colors.orange,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _formatAxis(double value) {
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  String _formatValue(double value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    if (abs >= 1000000) return '$sign\$${(abs / 1000000).toStringAsFixed(2)}M';
    if (abs >= 1000) return '$sign\$${(abs / 1000).toStringAsFixed(2)}k';
    return '$sign\$${abs.toStringAsFixed(2)}';
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final Color? color;

  const _TableCell(this.text, {this.isHeader = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
          color: isHeader ? Colors.white : color,
        ),
      ),
    );
  }
}
