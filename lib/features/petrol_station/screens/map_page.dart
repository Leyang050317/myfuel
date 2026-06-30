import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Screen displaying a mock interactive map view with petrol station markers.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int _selectedStationIndex = 0;

  // Mock petrol stations data
  final List<Map<String, dynamic>> _stations = [
    {
      'name': 'Petronas Station KLCC',
      'brand': 'Petronas',
      'brandColor': const Color(0xFF00A19C), // Teal
      'distance': '1.2 km',
      'time': '5 mins',
      'address': 'Lot 154, Jalan Ampang, Kuala Lumpur',
      'ron95': 'RM 2.05',
      'ron97': 'RM 3.47',
      'diesel': 'RM 3.35',
      'amenities': [Icons.local_atm, Icons.local_cafe, Icons.wash],
      'latOffset': 20.0,
      'lngOffset': -40.0,
    },
    {
      'name': 'Shell Station Ampang',
      'brand': 'Shell',
      'brandColor': const Color(0xFFFFD500), // Yellow
      'distance': '2.8 km',
      'time': '8 mins',
      'address': 'No 45, Jalan Ampang Hilir, Kuala Lumpur',
      'ron95': 'RM 2.05',
      'ron97': 'RM 3.47',
      'diesel': 'RM 3.35',
      'amenities': [Icons.local_atm, Icons.storefront, Icons.ev_station],
      'latOffset': -60.0,
      'lngOffset': 50.0,
    },
    {
      'name': 'Caltex Station Cheras',
      'brand': 'Caltex',
      'brandColor': const Color(0xFFD32F2F), // Red
      'distance': '4.5 km',
      'time': '12 mins',
      'address': 'Lot 1022, Jalan Cheras, Kuala Lumpur',
      'ron95': 'RM 2.05',
      'ron97': 'RM 3.47',
      'diesel': 'RM 3.35',
      'amenities': [Icons.local_atm, Icons.local_cafe, Icons.car_repair],
      'latOffset': 50.0,
      'lngOffset': 80.0,
    }
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedStation = _stations[_selectedStationIndex];

    return Scaffold(
      body: Stack(
        children: [
          // 1. Mock Map Canvas Background
          Container(
            color: const Color(0xFFE5E9F0), // Soft map background grey
            child: Stack(
              children: [
                // Abstract grid lines/roads mock
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapRoadsPainter(),
                  ),
                ),
                
                // Map markers (pins)
                ...List.generate(_stations.length, (index) {
                  final station = _stations[index];
                  final isSelected = index == _selectedStationIndex;
                  
                  // Calculate left/top coordinates to center-align the custom marker (width ~60, height ~70)
                  final leftOffset = MediaQuery.of(context).size.width / 2 + station['lngOffset'] - 30;
                  final topOffset = MediaQuery.of(context).size.height / 2.5 + station['latOffset'] - 35;
                  
                  return Positioned(
                    left: leftOffset,
                    top: topOffset,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedStationIndex = index;
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            duration: const Duration(milliseconds: 200),
                            scale: isSelected ? 1.25 : 1.0,
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 44,
                              color: isSelected ? AppTheme.primaryColor : station['brandColor'],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Text(
                              station['brand'],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // 2. Top search bar overlay
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: theme.colorScheme.onBackground.withOpacity(0.6)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search petrol station or location...',
                          hintStyle: TextStyle(fontSize: 14),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Filter options opened!'),
                            duration: Duration(milliseconds: 800),
                          ),
                        );
                      },
                    )
                  ],
                ),
              ),
            ),
          ),

          // 3. Sliding Station Details Bottom Sheet Card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Indicator & Distance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selectedStation['brandColor'].withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            selectedStation['brand'].toUpperCase(),
                            style: TextStyle(
                              color: selectedStation['brand'] == 'Shell' 
                                  ? Colors.orange.shade800 
                                  : selectedStation['brandColor'],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.navigation_outlined, size: 16, color: AppTheme.secondaryColor),
                            const SizedBox(width: 4),
                            Text(
                              '${selectedStation['distance']} (${selectedStation['time']})',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Station Name
                    Text(
                      selectedStation['name'],
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    
                    // Station Address
                    Text(
                      selectedStation['address'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Price Indicators Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPriceMiniTab(context, 'RON 95', selectedStation['ron95']),
                        _buildPriceMiniTab(context, 'RON 97', selectedStation['ron97']),
                        _buildPriceMiniTab(context, 'Diesel', selectedStation['diesel']),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Amenities & Navigate Button Row
                    Row(
                      children: [
                        // Amenities Icons
                        Row(
                          children: List.generate(
                            selectedStation['amenities'].length,
                            (idx) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                selectedStation['amenities'][idx],
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Navigate Button
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Navigating to ${selectedStation['name']}...'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          label: const Text('GO'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            minimumSize: Size.zero,
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPriceMiniTab(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }
}

/// Painter to draw mock roads on map background
class _MapRoadsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 28.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw background roads
    // Road 1 (Horizontal)
    final p1Start = Offset(-50, size.height * 0.4);
    final p1End = Offset(size.width + 50, size.height * 0.4);
    canvas.drawLine(p1Start, p1End, borderPaint);
    canvas.drawLine(p1Start, p1End, paint);

    // Road 2 (Vertical Curved)
    final path = Path()
      ..moveTo(size.width * 0.3, -50)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.4, size.width * 0.25, size.height + 50);
    canvas.drawPath(path, borderPaint);
    canvas.drawPath(path, paint);

    // Road 3 (Diagonal)
    final p3Start = Offset(size.width * 0.8, -50);
    final p3End = Offset(size.width * 0.1, size.height + 50);
    canvas.drawLine(p3Start, p3End, borderPaint);
    canvas.drawLine(p3Start, p3End, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
