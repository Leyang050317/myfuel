import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../fuel_tracking/models/fuel_claim_model.dart';
import '../../fuel_tracking/services/fuel_claim_service.dart';
import '../widgets/admin_shell.dart';

class FuelClaimsPage extends StatefulWidget {
  const FuelClaimsPage({super.key});

  @override
  State<FuelClaimsPage> createState() => _FuelClaimsPageState();
}

class _FuelClaimsPageState extends State<FuelClaimsPage> {
  final _service = FuelClaimService();

  List<FuelClaimModel> _claims = [];
  final Set<String> _updatingClaimIds = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _claims = await _service.loadClaims();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to load claims: $e')));
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _update(FuelClaimModel claim, String status) async {
    String? reason;

    if (status == 'Rejected') {
      reason = await showDialog<String>(
        context: context,
        builder: (_) => const _RejectClaimDialog(),
      );

      if (reason == null) {
        return;
      }
    }

    if (!mounted || _updatingClaimIds.contains(claim.id)) {
      return;
    }

    setState(() {
      _updatingClaimIds.add(claim.id);
    });

    try {
      await _service.updateStatus(claim.id, status, rejectionReason: reason);

      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claim ${status.toLowerCase()} successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to update claim: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingClaimIds.remove(claim.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminShell(
      title: 'Fuel Claims',
      selectedRoute: AppRoutes.fuelClaims,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _claims.isEmpty
          ? const Center(child: Text('No fuel claims found.'))
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _claims.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _PageHeader(
                    title: 'Fuel Claim Review',
                    subtitle:
                        'Review driver fuel spending and approve pending claims.',
                    count: '${_claims.length} claims',
                  );
                }

                final claim = _claims[index - 1];

                final isUpdating = _updatingClaimIds.contains(claim.id);

                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              foregroundColor: theme.colorScheme.primary,
                              child: const Icon(Icons.receipt_long_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    claim.calculation.vehicleDisplayName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${claim.calculation.distanceKm.toStringAsFixed(1)} km - '
                                    '${claim.calculation.fuelUsedLiters.toStringAsFixed(2)} L',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF697079),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _ClaimStatusChip(status: claim.status),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'RM ${claim.calculation.fuelCost.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (claim.status == 'Pending') ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              TextButton(
                                onPressed: isUpdating
                                    ? null
                                    : () => _update(claim, 'Approved'),
                                child: Text(
                                  isUpdating ? 'UPDATING...' : 'APPROVE',
                                ),
                              ),
                              TextButton(
                                onPressed: isUpdating
                                    ? null
                                    : () => _update(claim, 'Rejected'),
                                child: const Text('REJECT'),
                              ),
                            ],
                          ),
                        ],
                        if (claim.rejectionReason?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text('Reason: ${claim.rejectionReason}'),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String count;

  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF697079),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimStatusChip extends StatelessWidget {
  final String status;

  const _ClaimStatusChip({required this.status});

  Color get _color {
    switch (status) {
      case 'Approved':
        return const Color(0xFF2E7D32);

      case 'Rejected':
        return const Color(0xFFD32F2F);

      default:
        return const Color(0xFFFFA000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RejectClaimDialog extends StatefulWidget {
  const _RejectClaimDialog();

  @override
  State<_RejectClaimDialog> createState() => _RejectClaimDialogState();
}

class _RejectClaimDialogState extends State<_RejectClaimDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Claim'),
      content: TextField(
        controller: _reasonController,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        decoration: const InputDecoration(labelText: 'Reason (optional)'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_reasonController.text.trim());
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
