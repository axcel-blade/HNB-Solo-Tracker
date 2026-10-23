import 'package:flutter/material.dart';

import '../logic/place_routing.dart';
import '../models/place.dart';
import '../services/app_update.dart';
import '../services/release_link.dart';
import '../services/tracker_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/labeled_field.dart';
import '../widgets/update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store, required this.updates});

  final TrackerStore store;
  final UpdateChecker updates;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _checking = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _status = 'Checking GitHub…';
    });
    final result = await widget.updates.check();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _status = result.message;
    });
    if (result.status == UpdateStatus.available) {
      await showUpdateDialog(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _panel(
                    title: 'App update',
                    subtitle:
                        'Version ${widget.updates.currentVersion}. A newer GitHub release is shown when the app opens, and you can check again here.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppButton(
                          label: _checking ? 'Checking…' : 'Check for updates',
                          onPressed: _checking ? null : _check,
                        ),
                        if (_status.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            _status,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        AppButton(
                          label: 'Open GitHub releases',
                          kind: AppButtonKind.outline,
                          compact: true,
                          onPressed: () => openReleasePage(githubReleasesPage),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _panel(
                    title: 'Developer',
                    subtitle: 'HNB Solo Tracker is developed by $developerName.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          developerName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '@$githubUsername',
                          style: TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                        const SizedBox(height: 10),
                        AppButton(
                          label: githubProfileUrl,
                          kind: AppButtonKind.outline,
                          onPressed: () => openReleasePage(githubProfileUrl),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final kind in OrganizationKind.values) ...[
                    _PlaceSection(
                      kind: kind,
                      places: widget.store.places,
                      onAdd: widget.store.addPlace,
                      onDelete: (place) async {
                        final id = place.id;
                        if (id == null) return;
                        final ok = await confirmAction(
                          context,
                          'Remove ${place.headline} from the list?',
                        );
                        if (!ok || !mounted) return;
                        final error = await widget.store.deletePlace(id);
                        if (!mounted || error == null) return;
                        setState(() => _status = error);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceSection extends StatefulWidget {
  const _PlaceSection({
    required this.kind,
    required this.places,
    required this.onAdd,
    required this.onDelete,
  });

  final OrganizationKind kind;
  final List<CollectionPlace> places;
  final AddPlace onAdd;
  final Future<void> Function(CollectionPlace place) onDelete;

  @override
  State<_PlaceSection> createState() => _PlaceSectionState();
}

typedef AddPlace =
    Future<PlaceResult> Function({
      required OrganizationKind kind,
      required String organization,
      required String name,
    });

class _PlaceSectionState extends State<_PlaceSection> {
  final _organization = TextEditingController();
  final _name = TextEditingController();
  var _adding = false;
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _organization.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.onAdd(
      kind: widget.kind,
      organization: _organization.text,
      name: _name.text,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (result.place == null) {
        _error = result.error ?? placeNameMessage;
        return;
      }
      _adding = false;
      _organization.clear();
      _name.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final places = placesFor(widget.places, widget.kind);
    final hnb = widget.kind == OrganizationKind.hnb;
    final company = widget.kind == OrganizationKind.company;
    return _panel(
      title: widget.kind.label,
      subtitle: hnb
          ? 'Numbers from these branches are recorded as HNB.'
          : 'Numbers from these places are not recorded as HNB.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final place in places)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.pickerTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Records as ${place.recordedAs}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!place.builtIn && place.id != null)
                    AppButton(
                      label: 'Remove',
                      kind: AppButtonKind.outline,
                      compact: true,
                      onPressed: () => widget.onDelete(place),
                    ),
                ],
              ),
            ),
          if (places.isEmpty)
            const Text(
              'None yet.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          const SizedBox(height: 8),
          if (!_adding)
            AppButton(
              label: hnb
                  ? 'Add HNB branch'
                  : company
                  ? 'Add company'
                  : 'Add bank branch',
              kind: AppButtonKind.outline,
              onPressed: () => setState(() {
                _adding = true;
                _error = null;
              }),
            )
          else ...[
            if (!hnb)
              TextField(
                controller: _organization,
                decoration: appInputDecoration(
                  hint: company ? 'Company name' : 'Bank name',
                ),
              ),
            if (!hnb) const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: appInputDecoration(
                hint: hnb
                    ? 'Branch name'
                    : 'Branch or office. Leave blank for Head office',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.dangerFg, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                AppButton(
                  label: 'Cancel',
                  kind: AppButtonKind.outline,
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _adding = false;
                          _error = null;
                        }),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: _saving ? 'Saving…' : 'Save place',
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Widget _panel({
  required String title,
  required String subtitle,
  required Widget child,
}) {
  return Container(
    decoration: panelDecoration(),
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}
