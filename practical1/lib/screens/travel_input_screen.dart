import 'package:flutter/material.dart';
import 'result_screen.dart'; 

class TravelInputScreen extends StatefulWidget {
  const TravelInputScreen({super.key});

  @override
  State<TravelInputScreen> createState() => _TravelInputScreenState();
}

class _TravelInputScreenState extends State<TravelInputScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _destinationController = TextEditingController();
  final _durationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _participantsController = TextEditingController();
  
  String _selectedTravelType = 'Mid-Range';
  final List<String> _travelTypes = ['Budget', 'Mid-Range', 'Luxury'];

  @override
  void dispose() {
    _destinationController.dispose();
    _durationController.dispose();
    _budgetController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            destination: _destinationController.text,
            duration: int.parse(_durationController.text),
            budget: double.parse(_budgetController.text),
            participants: int.parse(_participantsController.text),
            travelType: _selectedTravelType,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Design Your Journey', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Where do you want to go?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Kyoto, Japan',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a destination' : null,
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Trip Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              
              // Grouped inputs in a row for a cleaner look
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Days',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _participantsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'People',
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Budget (RM)',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Travel Style',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              
              // Replaced Dropdown with Choice Chips for better UX
              Wrap(
                spacing: 8.0,
                children: _travelTypes.map((type) {
                  return ChoiceChip(
                    label: Text(type),
                    selected: _selectedTravelType == type,
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() => _selectedTravelType = type);
                      }
                    },
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: _selectedTravelType == type 
                          ? Theme.of(context).colorScheme.onPrimaryContainer 
                          : Colors.black87,
                      fontWeight: _selectedTravelType == type ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _submitForm,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Generate AI Itinerary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}