import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Screen for searching and filtering petrol stations by name, location, or brand.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchQuery = '';
  String _selectedBrand = 'All'; // Filter option: 'All', 'Petronas', 'Shell', 'Caltex'

  // Complete mock database of stations
  final List<Map<String, dynamic>> _allStations = [
    {
      'name': 'Petronas Station KLCC',
      'brand': 'Petronas',
      'brandColor': const Color(0xFF00A19C),
      'distance': '1.2 km',
      'address': 'Jalan Ampang, 50450 Kuala Lumpur',
      'ron95': 'RM 2.05',
      'ron97': 'RM 3.47',
      'diesel': 'RM 3.35',
      'amenities': [Icons.local_atm, Icons.local_cafe, Icons.wash],
      'popular': true,
    },
    {
      'name': 'Shell Station Ampang',
      'brand': 'Shell',
      'brandColor': const Color(0xFFFFD500),
      'distance': '2.8 km',
      'address': 'Jalan Ampang Hilir, 55000 Kuala Lumpur',
      'ron95': 'RM 2.05',
      'ron97': 'RM 3.47',
      'diesel': 'RM 3.35',
      'amenities': [Icons.local_atm, Icons.storefront, Icons.ev_station],
      'popular': true,
    },
    {
      'name': 'Caltex Station Cheras',
      'brand': 'Caltex',
      'brandColor': const Color(0xFFD32F2F),
      'distance': '4.5 km',
      'address': 'Jalan Cheras, 56000 Kuala Lumpur',
      'ron95': 'RM 2.05',
      'ron97': 'RM 3.47',
      'diesel': 'RM 3.35',
      'amenities': [Icons.local_atm, Icons.local_cafe, Icons.car_repair],
      'popular': false,
    },
    {
      'name': 'Petronas Station Bukit Bintang',
      'brand': 'Petronas',
      'brandColor': const Color(0xFF00A19C),
      'distance': '3.1 km',
      'address': 'Jalan Bukit Bintang, 55100 Kuala Lumpur',
      'ron95': 'RM 2.05',
      'ron97': 'RM 3.47',
      'diesel': 'RM 3.35',
      'amenities': [Icons.local_atm, Icons.storefront, Icons.wash],
      'popular': false,
    },
    {
      'name': 'Shell Station Pandan Indah',
      'brand': 'Shell',
      'brandColor': const Color(0xFFFFD500),
      'distance': '5.0 km',
      'address': 'Jalan Pandan Indah, 55100 Kuala Lumpur',
      'ron95': 'RM 2.05',
      'ron97': 'RM 3.47',
      'diesel': 'RM 3.35',
      'amenities': [Icons.local_atm, Icons.local_cafe, Icons.local_car_wash],
      'popular': false,
    },
    {
      'name': 'Caltex Station Ampang Jaya',
      'brand': 'Caltex',
      'brandColor': const Color(0xFFD32F2F),
      'distance': '6.2 km',
      'address': 'Jalan Ampang Jaya, 68000 Ampang, Selangor',
      'ron95': 'RM 2.05',
      'ron97': 'RM 3.47',
      'diesel': 'RM 3.35',
      'amenities': [Icons.local_atm, Icons.storefront],
      'popular': false,
    }
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Apply filters based on search query and selected brand chip
    final filteredStations = _allStations.where((station) {
      final matchesSearch = station['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          station['address'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesBrand = _selectedBrand == 'All' || station['brand'] == _selectedBrand;
      return matchesSearch && matchesBrand;
    }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Find Petrol Stations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.onBackground,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: TextFormField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Search station...',
                  hintText: 'Enter brand, road or city',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),

            // 2. Horizontal Filter Chips (M3 style)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
              child: Row(
                children: ['All', 'Petronas', 'Shell', 'Caltex'].map((brand) {
                  final isSelected = _selectedBrand == brand;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(brand),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onBackground,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      selectedColor: AppTheme.primaryColor,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedBrand = brand;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Stations List
            Expanded(
              child: filteredStations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_gas_station_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No petrol stations found.',
                            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      itemCount: filteredStations.length,
                      itemBuilder: (context, index) {
                        final station = filteredStations[index];
                        final isShell = station['brand'] == 'Shell';
                        final displayBrandColor = isShell ? Colors.orange.shade800 : station['brandColor'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left icon and brand colored square indicator
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: station['brandColor'].withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.local_gas_station_rounded,
                                    color: displayBrandColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                
                                // Middle information
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              station['name'],
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            station['distance'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        station['address'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onBackground.withOpacity(0.55),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Amenities icons row
                                      Row(
                                        children: [
                                          ...List.generate(
                                            station['amenities'].length,
                                            (idx) => Padding(
                                              padding: const EdgeInsets.only(right: 6.0),
                                              child: Icon(
                                                station['amenities'][idx],
                                                size: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          // Small navigate button
                                          GestureDetector(
                                            onTap: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Starting GPS to ${station['name']}'),
                                                  behavior: SnackBarBehavior.floating,
                                                  duration: const Duration(seconds: 1),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Text(
                                                'NAVIGATE',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
