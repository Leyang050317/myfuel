import 'package:flutter/material.dart';
import '../../fuel_tracking/models/fuel_claim_model.dart';
import '../../fuel_tracking/services/fuel_claim_service.dart';

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
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _update(FuelClaimModel claim, String status) async {
    String? reason;
    if (status == 'Rejected') {
      reason = await showDialog<String>(
        context: context,
        builder: (_) => const _RejectClaimDialog(),
      );
      if (reason == null) return;
    }
    if (!mounted || _updatingClaimIds.contains(claim.id)) return;
    setState(() => _updatingClaimIds.add(claim.id));
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
      if (mounted) setState(() => _updatingClaimIds.remove(claim.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Fuel Claims')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _claims.isEmpty
        ? const Center(child: Text('No fuel claims found.'))
        : ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: _claims.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final claim = _claims[index];
              final isUpdating = _updatingClaimIds.contains(claim.id);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.calculation.vehicleDisplayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${claim.calculation.distanceKm.toStringAsFixed(1)} km • ${claim.calculation.fuelUsedLiters.toStringAsFixed(2)} L',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'RM ${claim.calculation.fuelCost.toStringAsFixed(2)} • ${claim.status}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (claim.status == 'Pending')
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
                      if (claim.rejectionReason?.isNotEmpty == true)
                        Text('Reason: ${claim.rejectionReason}'),
                    ],
                  ),
                ),
              );
            },
          ),
  );
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_reasonController.text.trim()),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
