import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/place_routing.dart';
import '../models/catalog.dart';
import '../models/place.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';
import 'labeled_field.dart';

typedef OptionSelection = ({CollectionPlace place, String? category});

typedef AddPlaceCallback =
    Future<PlaceResult> Function({
      required OrganizationKind kind,
      required String organization,
      required String name,
    });

Future<OptionSelection?> showOptionsDialog(
  BuildContext context, {
  required String phone,
  required List<CollectionPlace> places,
  required AddPlaceCallback onAddPlace,
  CollectionPlace? initialPlace,
  bool placeOnly = false,
}) {
  return showDialog<OptionSelection>(
    context: context,
    barrierColor: AppColors.backdrop,
    builder: (context) => OptionsDialog(
      phone: phone,
      places: places,
      onAddPlace: onAddPlace,
      initialPlace: initialPlace,
      placeOnly: placeOnly,
    ),
  );
}

class OptionsDialog extends StatefulWidget {
  const OptionsDialog({
    super.key,
    required this.phone,
    required this.places,
    required this.onAddPlace,
    this.initialPlace,
    this.placeOnly = false,
  });

  final String phone;
  final List<CollectionPlace> places;
  final AddPlaceCallback onAddPlace;
  final CollectionPlace? initialPlace;
  final bool placeOnly;

  @override
  State<OptionsDialog> createState() => _OptionsDialogState();
}

class _OptionsDialogState extends State<OptionsDialog> {
  late List<CollectionPlace> _places;
  late OrganizationKind _kind;
  CollectionPlace? _selected;
  String? _category;
  final _search = TextEditingController();
  final _organization = TextEditingController();
  final _branchName = TextEditingController();
  var _step = 1;
  var _adding = false;
  var _savingPlace = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _places = widget.places;
    _selected = widget.initialPlace;
    _kind = widget.initialPlace?.kind ?? OrganizationKind.hnb;
    if (!widget.placeOnly && widget.initialPlace != null) _step = 2;
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _organization.dispose();
    _branchName.dispose();
    super.dispose();
  }

  bool get _placeStep => _step == 1;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final listHeight = math.min(300.0, math.max(140.0, height - 420));
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: height - 36),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _placeStep ? 'STEP 1 OF 2' : 'STEP 2 OF 2',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _placeStep
                    ? 'Where was this number collected?'
                    : 'Select the Solo category',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _placeStep
                    ? _placeHelp
                    : 'Choose which column this entry should be counted in.',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (_placeStep && _adding)
                _addForm()
              else if (_placeStep) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final kind in OrganizationKind.values)
                      _KindChip(
                        label: kind.label,
                        selected: _kind == kind,
                        onTap: () => setState(() {
                          _kind = kind;
                          if (_selected?.kind != kind) _selected = null;
                          _formError = null;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  decoration: appInputDecoration(
                    hint: 'Find a branch or company',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(height: listHeight, child: _placeList()),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    label: _addLabel,
                    kind: AppButtonKind.outline,
                    compact: true,
                    onPressed: () => setState(() {
                      _adding = true;
                      _formError = null;
                      _organization.clear();
                      _branchName.clear();
                    }),
                  ),
                ),
              ] else
                _ChoiceGrid(
                  columns: MediaQuery.sizeOf(context).width > 480 ? 2 : 1,
                  children: [
                    for (final category in SoloCategory.all)
                      _ChoiceTile(
                        title: category.name,
                        subtitle: 'Count this entry in this category.',
                        selected: _category == category.id,
                        onTap: () => setState(() => _category = category.id),
                      ),
                  ],
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  AppButton(
                    label: _backLabel,
                    kind: AppButtonKind.outline,
                    onPressed: _savingPlace ? null : _back,
                  ),
                  const Spacer(),
                  AppButton(
                    label: _forwardLabel,
                    onPressed: _canContinue && !_savingPlace ? _forward : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _placeHelp {
    final phone = widget.phone.trim();
    final target = phone.isEmpty ? 'these numbers' : phone;
    return 'HNB branches are the only places recorded as HNB. '
        'Choose where $target was collected.';
  }

  String get _addLabel => switch (_kind) {
    OrganizationKind.hnb => 'Add HNB branch',
    OrganizationKind.bank => 'Add bank branch',
    OrganizationKind.company => 'Add company',
  };

  String get _backLabel {
    if (_adding) return 'Back';
    if (_placeStep) return 'Cancel';
    return '← Back';
  }

  String get _forwardLabel {
    if (_adding) return 'Save place';
    if (widget.placeOnly || _placeStep) {
      return widget.placeOnly ? 'Use this place' : 'Next →';
    }
    return 'Save entry ✓';
  }

  bool get _canContinue {
    if (_adding) return true;
    if (_placeStep) return _selected != null;
    return _category != null;
  }

  void _back() {
    if (_adding) {
      setState(() {
        _adding = false;
        _formError = null;
      });
      return;
    }
    if (_placeStep) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _forward() async {
    if (_adding) {
      await _savePlace();
      return;
    }
    if (_placeStep) {
      if (widget.placeOnly) {
        Navigator.of(context).pop((place: _selected!, category: null));
        return;
      }
      setState(() => _step = 2);
      return;
    }
    Navigator.of(context).pop((place: _selected!, category: _category));
  }

  Future<void> _savePlace() async {
    setState(() {
      _savingPlace = true;
      _formError = null;
    });
    final result = await widget.onAddPlace(
      kind: _kind,
      organization: _organization.text,
      name: _branchName.text,
    );
    if (!mounted) return;
    if (result.place == null) {
      setState(() {
        _savingPlace = false;
        _formError = result.error;
      });
      return;
    }
    final saved = result.place!;
    setState(() {
      _savingPlace = false;
      _adding = false;
      _formError = null;
      if (!_places.any((place) => place.identity == saved.identity)) {
        _places = [..._places, saved];
      }
      _selected = saved;
      _kind = saved.kind;
      _search.text = saved.kind == OrganizationKind.hnb
          ? saved.name
          : saved.organization;
    });
  }

  Widget _placeList() {
    final matches = placesFor(_places, _kind, query: _search.text);
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            emptyPlaceMessage(_kind, _places, _search.text),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: matches.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final place = matches[index];
        return _ChoiceTile(
          title: place.pickerTitle,
          subtitle: 'Records as ${place.recordedAs}',
          selected: _selected?.identity == place.identity,
          onTap: () => setState(() => _selected = place),
        );
      },
    );
  }

  Widget _addForm() {
    final hnb = _kind == OrganizationKind.hnb;
    final company = _kind == OrganizationKind.company;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hnb)
          TextField(
            controller: _organization,
            decoration: appInputDecoration(
              hint: company ? 'Company name' : 'Bank name',
            ),
          ),
        if (!hnb) const SizedBox(height: 10),
        TextField(
          controller: _branchName,
          decoration: appInputDecoration(
            hint: hnb
                ? 'HNB branch name'
                : company
                ? 'Office name, or leave blank for Head office'
                : 'Branch name, or leave blank for Head office',
          ),
        ),
        if (_formError != null) ...[
          const SizedBox(height: 8),
          Text(
            _formError!,
            style: const TextStyle(color: AppColors.dangerFg, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.choiceSelected : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? AppColors.blue : AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.blue : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < children.length; index += columns) {
      final end = index + columns > children.length
          ? children.length
          : index + columns;
      final slice = children.sublist(index, end);
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var slot = 0; slot < columns; slot++) ...[
              if (slot > 0) const SizedBox(width: 12),
              Expanded(
                child: slot < slice.length ? slice[slot] : const SizedBox(),
              ),
            ],
          ],
        ),
      );
      if (end < children.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.choiceSelected : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: selected ? AppColors.blue : AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        hoverColor: AppColors.choiceHover,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
