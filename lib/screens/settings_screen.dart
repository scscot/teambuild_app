// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../widgets/header_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/states_by_country.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _directSponsorMinController =
      TextEditingController();
  final TextEditingController _totalTeamMinController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bizNameController = TextEditingController();
  final TextEditingController _bizNameConfirmController =
      TextEditingController();
  final TextEditingController _refLinkController = TextEditingController();
  final TextEditingController _refLinkConfirmController =
      TextEditingController();

  List<String> _selectedCountries = [];
  bool _selectAllCountries = false;

  List<String> _originalSelectedCountries = [];
  int _directSponsorMin = 5;
  int _totalTeamMin = 10;
  bool _isLocked = false;
  String? _userCountry;
  String? _bizOpp;
  String? _bizRefUrl;

  List<String> get allCountries {
    final fullList = statesByCountry.keys.toList();
    final selected = List<String>.from(_selectedCountries);
    final unselected = fullList.where((c) => !selected.contains(c)).toList();

    selected.remove(_userCountry);
    unselected.remove(_userCountry);

    selected.sort();
    unselected.sort();

    if (_userCountry != null) {
      return [_userCountry!, ...selected, ...unselected];
    }
    return [...selected, ...unselected];
  }

  Future<void> _loadUserSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      final country = data['country'];
      final countries = List<String>.from(data['countries'] ?? []);
      final bizOpp = data['biz_opp'];
      final bizRefUrl = data['biz_opp_ref_url'];
      final sponsorMin = data['direct_sponsor_min'];
      final teamMin = data['total_team_min'];

      setState(() {
        if (country is String) {
          _userCountry = country;
          if (!countries.contains(country)) countries.insert(0, country);
        }
        _selectedCountries = countries;
        _originalSelectedCountries = List.from(countries);
        _bizOpp = bizOpp;
        _bizRefUrl = bizRefUrl;
        _directSponsorMin = sponsorMin ?? 5;
        _totalTeamMin = teamMin ?? 10;
        _directSponsorMinController.text = _directSponsorMin.toString();
        _totalTeamMinController.text = _totalTeamMin.toString();
        _isLocked = _bizOpp != null && _bizRefUrl != null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bizNameController.text != _bizNameConfirmController.text ||
        _refLinkController.text != _refLinkConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fields must match for confirmation.')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    await userDoc.update({
      if (!_isLocked) 'biz_opp': _bizNameController.text.trim(),
      if (!_isLocked) 'biz_opp_ref_url': _refLinkController.text.trim(),
      'direct_sponsor_min': _directSponsorMin,
      'total_team_min': _totalTeamMin,
      'countries': _selectedCountries,
    });

    await _loadUserSettings();
    Scrollable.ensureVisible(_formKey.currentContext ?? context,
        duration: Duration(milliseconds: 300));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully.')),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeaderWithMenu(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: ScrollController(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Business Opportunity Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLocked && _bizOpp != null && _bizRefUrl != null) ...[
                const Text('Business Opportunity Name',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_bizOpp!, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Your Unique Referral Link',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_bizRefUrl!, style: const TextStyle(fontSize: 16)),
              ] else ...[
                const Text(
                    "Enter the name of your business opportunity. You can set this only once, and it cannot be changed later."),
                TextFormField(
                  controller: _bizNameController,
                  enabled: !_isLocked,
                  decoration: const InputDecoration(
                      labelText: 'Business Opportunity Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _bizNameConfirmController,
                  enabled: !_isLocked,
                  decoration: const InputDecoration(
                      labelText: 'Confirm Business Opportunity Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                const Text(
                    "Enter your unique business opportunity referral link. You can set this only once, and it cannot be changed later."),
                TextFormField(
                  controller: _refLinkController,
                  enabled: !_isLocked,
                  decoration: const InputDecoration(
                      labelText: 'Your Unique Referral Link URL'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _refLinkConfirmController,
                  enabled: !_isLocked,
                  decoration: const InputDecoration(
                      labelText: 'Confirm Referral Link URL'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 24),
              const Text('Available Countries',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Important:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    TextSpan(
                      text:
                          ' Only select the countries where your business opportunity is currently available.',
                    ),
                  ],
                ),
              ),
              CheckboxListTile(
                title: const Text('Select All Countries'),
                value: _selectAllCountries,
                onChanged: (value) {
                  setState(() {
                    _selectAllCountries = value!;
                    if (_selectAllCountries) {
                      _selectedCountries = List.from(allCountries);
                    } else {
                      _selectedCountries =
                          List.from(_originalSelectedCountries);
                    }
                  });
                },
              ),
              MultiSelectDialogField<String>(
                items: allCountries
                    .map((e) => MultiSelectItem<String>(e, e))
                    .toList(),
                initialValue: _selectedCountries,
                title: const Text("Select Countries"),
                buttonText: const Text("Or Select Individual Countries"),
                searchable: true,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.deepPurple.shade200,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                buttonIcon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.deepPurple,
                ),
                selectedColor: Colors.deepPurple,
                dialogHeight: 500,
                chipDisplay: MultiSelectChipDisplay(
                  chipColor: Colors.deepPurple.shade100,
                  textStyle: const TextStyle(color: Colors.black87),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onConfirm: (values) {
                  setState(() {
                    _selectedCountries = List.from(values);
                  });
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: const Text(
                  'TeamBuild Pro is your downline’s launchpad!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text:
                          "It helps each member pre-build their team for free—before ever joining ",
                    ),
                    TextSpan(
                      text: _bizOpp ?? 'your business opportunity',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                    TextSpan(
                      text: ".",
                    ),
                    TextSpan(
                      text:
                          "\n\nOnce they meet the eligibility criteria you set below, they’ll automatically receive an invitation to join ",
                    ),
                    TextSpan(
                      text: _bizOpp ?? 'business opportunity',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                    const TextSpan(
                      text:
                          " with their entire pre-built TeamBuild Pro downline ready to follow them into your ",
                    ),
                    TextSpan(
                      text: _bizOpp ?? 'your business opportunity',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                    const TextSpan(text: ' organization.'),
                    const TextSpan(
                      text:
                          "\n\nSet challenging requirements to ensure your downline members enter ",
                    ),
                    TextSpan(
                      text: _bizOpp ?? 'your business opportunity',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                    const TextSpan(
                      text:
                          " strong, aligned, and positioned for long-term success!",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                // Wrap your Text widget with Center
                child: Text(
                  'Set Minimum Eligibility Requirements',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _directSponsorMinController,
                      decoration: InputDecoration(
                        labelText: 'Direct Sponsors',
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _directSponsorMin = int.tryParse(value) ?? 5;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _totalTeamMinController,
                      decoration: InputDecoration(
                        labelText: 'Total Team Members',
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _totalTeamMin = int.tryParse(value) ?? 10;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Save Settings'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
