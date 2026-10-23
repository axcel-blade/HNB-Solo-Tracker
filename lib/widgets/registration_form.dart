import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/collection_logic.dart';
import '../models/registration_catalog.dart';
import '../theme/app_theme.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key, required this.onSave});

  final Future<String?> Function(RegistrationInput input) onSave;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _phoneController = TextEditingController();
  final _ownVisitController = TextEditingController();
  final _phoneFocus = FocusNode();
  var _bankType = BankTypes.hnb;
  var _memberStatus = MemberStatuses.oldActive;
  var _product = ProductTypes.soloMax;
  var _otherSource = MemberStatuses.card;
  var _channel = ChannelTypes.branch;
  var _branch = namedHnbBranches.first;
  var _department = hnbDepartments.first;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _phoneFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _ownVisitController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    final error = await widget.onSave(
      RegistrationInput(
        phone: _phoneController.text,
        bankType: _bankType,
        hnbMemberStatus: _memberStatus,
        hnbProduct: _product,
        otherSource: _otherSource,
        channelType: _channel,
        branch: _branch,
        department: _department,
        ownVisit: _ownVisitController.text,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) return;
    _phoneController.clear();
    _ownVisitController.clear();
    _phoneFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final hnb = _bankType == BankTypes.hnb;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = const Text(
                'New Customer Entry Form',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              );
              const hint = Text(
                'Step-by-step logic tracking',
                style: TextStyle(color: PortalColors.faint, fontSize: 12),
              );
              final heading = Row(
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    color: PortalColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: title),
                  if (constraints.maxWidth >= 520) hint,
                ],
              );
              if (constraints.maxWidth >= 520) return heading;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, hint],
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: PortalColors.line),
          const SizedBox(height: 18),
          const _FieldLabel('Contact / Reference Number', requiredMark: true),
          TextField(
            key: const Key('reference-field'),
            controller: _phoneController,
            focusNode: _phoneFocus,
            textInputAction: TextInputAction.done,
            maxLength: 120,
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            style: const TextStyle(color: PortalColors.text),
            decoration: _inputDecoration('e.g. 0771234567 or Ref #1029'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Bank Provider Category', requiredMark: true),
          Row(
            children: [
              Expanded(
                child: _Choice(
                  title: 'HNB Bank',
                  subtitle: 'Hatton National Bank',
                  selected: hnb,
                  selectedColor: PortalColors.gold,
                  fill: PortalColors.blue.withValues(alpha: 0.55),
                  onTap: () => setState(() => _bankType = BankTypes.hnb),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Choice(
                  title: 'Other Bank',
                  subtitle: 'External Bank Member',
                  selected: !hnb,
                  selectedColor: PortalColors.purple,
                  fill: const Color(0xFF581C87).withValues(alpha: 0.45),
                  onTap: () => setState(() => _bankType = BankTypes.other),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hnb)
            _Inset(
              title: 'HNB CUSTOMER CLASSIFICATION',
              titleColor: PortalColors.gold,
              children: [
                const _FieldLabel('Member Status', small: true),
                Row(
                  children: [
                    Expanded(
                      child: _Choice(
                        title: MemberStatuses.oldActive,
                        selected: _memberStatus == MemberStatuses.oldActive,
                        selectedColor: PortalColors.gold,
                        onTap: () => setState(
                          () => _memberStatus = MemberStatuses.oldActive,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Choice(
                        title: MemberStatuses.newActive,
                        selected: _memberStatus == MemberStatuses.newActive,
                        selectedColor: PortalColors.gold,
                        onTap: () => setState(
                          () => _memberStatus = MemberStatuses.newActive,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _FieldLabel('Product Type', small: true),
                Row(
                  children: [
                    Expanded(
                      child: _Choice(
                        title: ProductTypes.soloMax,
                        selected: _product == ProductTypes.soloMax,
                        selectedColor: PortalColors.gold,
                        onTap: () =>
                            setState(() => _product = ProductTypes.soloMax),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Choice(
                        title: ProductTypes.hnbAcc,
                        selected: _product == ProductTypes.hnbAcc,
                        selectedColor: PortalColors.gold,
                        onTap: () =>
                            setState(() => _product = ProductTypes.hnbAcc),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            _Inset(
              title: 'OTHER BANK PAYMENT SOURCE',
              titleColor: PortalColors.purple,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Choice(
                        title: 'Credit / Debit Card',
                        selected: _otherSource == MemberStatuses.card,
                        selectedColor: PortalColors.purple,
                        onTap: () =>
                            setState(() => _otherSource = MemberStatuses.card),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Choice(
                        title: 'Bank Account',
                        selected: _otherSource == MemberStatuses.account,
                        selectedColor: PortalColors.purple,
                        onTap: () => setState(
                          () => _otherSource = MemberStatuses.account,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: PortalColors.line),
          const SizedBox(height: 16),
          const _FieldLabel('Acquisition Channel / Location', requiredMark: true),
          Row(
            children: [
              Expanded(
                child: _Choice(
                  title: 'HNB Branch',
                  selected: _channel == ChannelTypes.branch,
                  selectedColor: PortalColors.amber,
                  onTap: () => setState(() => _channel = ChannelTypes.branch),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Choice(
                  title: 'Department',
                  selected: _channel == ChannelTypes.department,
                  selectedColor: PortalColors.emerald,
                  onTap: () =>
                      setState(() => _channel = ChannelTypes.department),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Choice(
                  title: 'Own Visit',
                  selected: _channel == ChannelTypes.ownVisit,
                  selectedColor: PortalColors.pink,
                  onTap: () => setState(() => _channel = ChannelTypes.ownVisit),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_channel == ChannelTypes.branch) ...[
            const _FieldLabel(
              'Select Branch (256 Sri Lankan Branches)',
              small: true,
            ),
            _MenuField(
              value: _branch,
              items: allHnbBranches(),
              onChanged: (value) => setState(() => _branch = value),
            ),
          ] else if (_channel == ChannelTypes.department) ...[
            const _FieldLabel('Select HNB Tower Department', small: true),
            _MenuField(
              value: _department,
              items: hnbDepartments,
              onChanged: (value) => setState(() => _department = value),
            ),
          ] else ...[
            const _FieldLabel(
              'Visit Location / Merchant / Field Event Name',
              small: true,
            ),
            TextField(
              key: const Key('visit-field'),
              controller: _ownVisitController,
              style: const TextStyle(color: PortalColors.text),
              decoration: _inputDecoration(
                'e.g. Majestic City Promo Event, Merchant Onboarding Stall',
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: PortalColors.gold,
              foregroundColor: PortalColors.darkBlue,
              disabledBackgroundColor: PortalColors.gold.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Save Customer Entry'),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, size: 14, color: PortalColors.faint),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'All inputs autosaved locally on this device.',
                  style: TextStyle(color: PortalColors.faint, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuField extends StatelessWidget {
  const _MenuField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: PortalColors.card,
      style: const TextStyle(color: PortalColors.text, fontSize: 14),
      decoration: _inputDecoration(null),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

InputDecoration _inputDecoration(String? hint) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: PortalColors.inputBorder),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: PortalColors.faint, fontSize: 14),
    filled: true,
    fillColor: PortalColors.input,
    isDense: true,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: border,
    border: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: PortalColors.gold, width: 1.4),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.small = false, this.requiredMark = false});

  final String text;
  final bool small;
  final bool requiredMark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (requiredMark)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: PortalColors.gold),
              ),
          ],
        ),
        style: TextStyle(
          color: small ? PortalColors.faint : PortalColors.muted,
          fontSize: small ? 12 : 14,
          fontWeight: small ? FontWeight.w500 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _Inset extends StatelessWidget {
  const _Inset({
    required this.title,
    required this.titleColor,
    required this.children,
  });

  final String title;
  final Color titleColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PortalColors.bg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PortalColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
    this.subtitle,
    this.fill,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final Color selectedColor;
  final Color? fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? (fill ?? selectedColor.withValues(alpha: 0.12)) : PortalColors.input,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? selectedColor : PortalColors.inputBorder,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? selectedColor : PortalColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: subtitle == null ? 12 : 14,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: PortalColors.faint, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PortalColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PortalColors.line),
      ),
      child: child,
    );
  }
}
