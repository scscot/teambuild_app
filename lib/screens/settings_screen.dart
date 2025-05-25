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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bizNameController = TextEditingController();
  final TextEditingController _bizNameConfirmController = TextEditingController();
  final TextEditingController _refLinkController = TextEditingController();
  final TextEditingController _refLinkConfirmController = TextEditingController();

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
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
    Scrollable.ensureVisible(_formKey.currentContext ?? context, duration: Duration(milliseconds: 300));

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
                const Text('Business Opportunity Name', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_bizOpp!, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Your Unique Referral Link', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_bizRefUrl!, style: const TextStyle(fontSize: 16)),
              ] else ...[
                const Text("Enter the name of your business opportunity. You can set this only once, and it cannot be changed later."),
                TextFormField(
                  controller: _bizNameController,
                  enabled: !_isLocked,
                  decoration: const InputDecoration(labelText: 'Business Opportunity Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _bizNameConfirmController,
                  enabled: !_isLocked,
                  decoration: const InputDecoration(labelText: 'Confirm Business Opportunity Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                const Text("Enter your unique business opportunity referral link. You can set this only once, and it cannot be changed later."),
                TextFormField(
                  controller: _refLinkController,
                  enabled: !_isLocked,
                  decoration: const InputDecoration(labelText: 'Your Unique Referral Link URL'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _refLinkConfirmController,
                  enabled: !_isLocked,
                  decoration: const InputDecoration(labelText: 'Confirm Referral Link URL'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 24),
              const Text('Available Countries', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Select the countries where your business opportunity is available. You can also choose 'All Countries."),
              CheckboxListTile(
                title: const Text('Select All Countries'),
                value: _selectAllCountries,
                onChanged: (value) {
                  setState(() {
                    _selectAllCountries = value!;
                    if (_selectAllCountries) {
                      _selectedCountries = List.from(allCountries);
                    } else {
                      _selectedCountries = List.from(_originalSelectedCountries);
                    }
                  });
                },
              ),
              // PATCH START: Replace FilterChip layout with multi-select modal
              MultiSelectDialogField<String>(
                items: allCountries.map((e) => MultiSelectItem<String>(e, e)).toList(),
                initialValue: _selectedCountries,
                title: const Text("Countries"),
                buttonText: const Text("Select Individual Countries"),
                searchable: true,
                onConfirm: (values) {
                  setState(() {
                    _selectedCountries = List.from(values);
                  });
                },
              ),
              // PATCH END
              const SizedBox(height: 24),
              const Text('Eligibility Requirements', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                  "Once a downline member meets the minimum direct sponsor and total team size criteria, they'll receive an invitation and referral link to join ${_bizOpp ?? 'your business opportunity'}.",
                ),

              TextFormField(
                initialValue: _directSponsorMin.toString(),
                decoration: const InputDecoration(labelText: 'Minimum Direct Sponsors'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _directSponsorMin = int.tryParse(value) ?? 5;
                  });
                },
              ),
              TextFormField(
                initialValue: _totalTeamMin.toString(),
                decoration: const InputDecoration(labelText: 'Minimum Total Team Members'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _totalTeamMin = int.tryParse(value) ?? 10;
                  });
                },
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
