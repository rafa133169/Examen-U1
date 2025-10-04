import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF005f73);

    // Light Theme
    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: seedColor, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );

    // Dark Theme
    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        background: const Color(0xFF1a1a1a),
      ),
      textTheme: GoogleFonts.latoTextTheme(
        Theme.of(
          context,
        ).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: seedColor, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF00343d),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );

    return MaterialApp(
      title: 'Control de Aforo – Ferry Cozumel',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system, // Automatically adapts to system theme
      home: const FerryControlScreen(),
    );
  }
}

class HistoryEvent {
  final String text;
  final EventType type;
  HistoryEvent(this.text, this.type);
}

enum EventType { entry, exit, reset }

class FerryControlScreen extends StatefulWidget {
  const FerryControlScreen({super.key});
  @override
  _FerryControlScreenState createState() => _FerryControlScreenState();
}

class _FerryControlScreenState extends State<FerryControlScreen>
    with TickerProviderStateMixin {
  int _capacity = 100;
  int _currentAforo = 0;
  final List<HistoryEvent> _history = [];
  final TextEditingController _capacityController = TextEditingController();
  final FocusNode _capacityFocusNode = FocusNode();
  bool _isCapacitySet = false;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  
  // Carousel related
  late PageController _pageController;
  late Timer _carouselTimer;
  int _currentCarouselIndex = 0;
  
  final List<String> _carouselImages = [
    'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/14/fd/0d/68/disfruta-de-los-colores.jpg?w=900&h=500&s=1',
    'https://images.unsplash.com/photo-1582719508461-905c673771fd?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1544551763-46a013bb70d5?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _capacityController.text = _capacity.toString();
    
    // Initialize animation controllers
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Initialize carousel
    _pageController = PageController();
    _startCarouselTimer();
    
    // Start initial animations
    _slideController.forward();
    _scaleController.forward();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentCarouselIndex = (_currentCarouselIndex + 1) % _carouselImages.length;
        _pageController.animateToPage(
          _currentCarouselIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _capacityFocusNode.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _pageController.dispose();
    _carouselTimer.cancel();
    super.dispose();
  }

  void _applyCapacity() {
    setState(() {
      _capacity = int.tryParse(_capacityController.text) ?? _capacity;
      _isCapacitySet = true;
      _capacityFocusNode.unfocus();
    });
  }

  void _updateAforo(int change, String operation, EventType type) {
    if (!_isCapacitySet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, aplique una capacidad máxima primero.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Trigger button animation
    _scaleController.reset();
    _scaleController.forward();
    
    setState(() {
      final newAforo = _currentAforo + change;
      if (newAforo >= 0 && newAforo <= _capacity) {
        _currentAforo = newAforo;
        _history.insert(
          0,
          HistoryEvent('$operation → Aforo: $_currentAforo/$_capacity', type),
        );
      }
    });
  }

  void _resetAforo() {
    // Trigger rotation animation for reset
    _rotationController.reset();
    _rotationController.forward();
    
    setState(() {
      _currentAforo = 0;
      _history.insert(
        0,
        HistoryEvent('Reinicio → Aforo: 0/$_capacity', EventType.reset),
      );
      _isCapacitySet = false;
    });
  }

  Color _getSemaphoreColor() {
    if (_capacity == 0) return Colors.green;
    final percentage = _currentAforo / _capacity;
    if (percentage >= 0.9) return Colors.red;
    if (percentage >= 0.6) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semaphoreColor = _getSemaphoreColor();

    return Scaffold(
      appBar: AppBar(title: const Text('Control de Aforo – Ferry Cozumel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Enhanced Photo Carousel
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _slideController,
                curve: Curves.elasticOut,
              )),
              child: Container(
                height: 220,
                margin: const EdgeInsets.only(bottom: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentCarouselIndex = index;
                          });
                        },
                        itemCount: _carouselImages.length,
                        itemBuilder: (context, index) {
                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double value = 1.0;
                              if (_pageController.position.haveDimensions) {
                                value = _pageController.page! - index;
                                value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                              }
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(
                                      _carouselImages[index],
                                      height: 220,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          height: 220,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.grey.shade300,
                                                Colors.grey.shade100,
                                                Colors.grey.shade300,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 220,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            color: Colors.grey.shade300,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // Carousel indicators
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _carouselImages.asMap().entries.map((entry) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _currentCarouselIndex == entry.key ? 12 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentCarouselIndex == entry.key
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Gradient overlay for better text readability
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Enhanced Capacity Input with Animation
            FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.5, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
                )),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer.withOpacity(0.3),
                        theme.colorScheme.secondaryContainer.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _capacityController,
                          focusNode: _capacityFocusNode,
                          enabled: !_isCapacitySet,
                          decoration: InputDecoration(
                            labelText: 'Capacidad Máxima',
                            prefixIcon: const Icon(Icons.people),
                            filled: true,
                            fillColor: theme.colorScheme.surface.withOpacity(0.8),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      if (!_isCapacitySet) ...[
                        const SizedBox(width: 16),
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _scaleController,
                              curve: Curves.elasticOut,
                            ),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _applyCapacity,
                            icon: const Icon(Icons.check),
                            label: const Text('Aplicar'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Enhanced Occupation Card with Animation
            FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.5, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
                )),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        semaphoreColor.withOpacity(0.1),
                        theme.colorScheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: semaphoreColor.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Card(
                    elevation: 0,
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.groups,
                                      color: theme.colorScheme.primary,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ocupación',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                AnimatedDefaultTextStyle(
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: semaphoreColor,
                                  ) ?? const TextStyle(),
                                  duration: const Duration(milliseconds: 300),
                                  child: Text('$_currentAforo / $_capacity'),
                                ),
                                const SizedBox(height: 16),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  height: 16,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            semaphoreColor.withOpacity(0.2),
                                            semaphoreColor.withOpacity(0.1),
                                          ],
                                        ),
                                      ),
                                      child: LinearProgressIndicator(
                                        value: _capacity > 0
                                            ? _currentAforo / _capacity
                                            : 0.0,
                                        backgroundColor: Colors.transparent,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          semaphoreColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedDefaultTextStyle(
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ) ?? const TextStyle(),
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    '${(_capacity > 0 ? (_currentAforo / _capacity * 100) : 0).toStringAsFixed(1)}% ocupado',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildSemaphoreLight(
                                  Colors.red,
                                  semaphoreColor,
                                  theme,
                                ),
                                _buildSemaphoreLight(
                                  Colors.yellow,
                                  semaphoreColor,
                                  theme,
                                ),
                                _buildSemaphoreLight(
                                  Colors.green,
                                  semaphoreColor,
                                  theme,
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Enhanced Control Buttons with Staggered Animation
            FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
                )),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildControlButton(
                      context,
                      icon: Icons.add,
                      text: '+1',
                      color: Colors.green,
                      onPressed: () => _updateAforo(1, 'Entró +1', EventType.entry),
                    ),
                    _buildControlButton(
                      context,
                      icon: Icons.group_add,
                      text: '+5',
                      color: Colors.green,
                      onPressed: () =>
                          _updateAforo(5, 'Entraron +5', EventType.entry),
                    ),
                    _buildControlButton(
                      context,
                      icon: Icons.remove,
                      text: '-1',
                      color: Colors.orange,
                      onPressed: () => _updateAforo(-1, 'Salió -1', EventType.exit),
                    ),
                    _buildControlButton(
                      context,
                      icon: Icons.group_remove,
                      text: '-5',
                      color: Colors.orange,
                      onPressed: () =>
                          _updateAforo(-5, 'Salieron -5', EventType.exit),
                    ),
                    _buildControlButton(
                      context,
                      icon: Icons.refresh,
                      text: 'Reiniciar',
                      color: Colors.red,
                      onPressed: _resetAforo,
                      isSpecial: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Enhanced History Section
            FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Historial de Eventos',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 0,
                      child: _history.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_note,
                                    size: 48,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay eventos registrados.',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Los cambios en el aforo aparecerán aquí',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _history.length,
                              itemBuilder: (context, index) {
                                final event = _history[index];
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 300 + (index * 100)),
                                  curve: Curves.easeOutBack,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [
                                          _getEventColor(event.type).withOpacity(0.1),
                                          theme.colorScheme.surface,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _getEventColor(event.type).withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getEventIcon(event.type),
                                          color: _getEventColor(event.type),
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        event.text,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: _getEventColor(event.type),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemaphoreLight(
    Color lightColor,
    Color activeColor,
    ThemeData theme, {
    bool isLast = false,
  }) {
    final bool isActive = lightColor == activeColor;
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            if (isActive)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: lightColor.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            // Main light
            FadeTransition(
              opacity: isActive
                  ? _pulseController
                  : const AlwaysStoppedAnimation(0.3),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: isActive 
                    ? lightColor 
                    : theme.colorScheme.outline.withOpacity(0.3),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: isActive 
                      ? lightColor.withOpacity(0.8)
                      : Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.entry:
        return Icons.trending_up;
      case EventType.exit:
        return Icons.trending_down;
      case EventType.reset:
        return Icons.refresh;
    }
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.entry:
        return Colors.green;
      case EventType.exit:
        return Colors.orange;
      case EventType.reset:
        return Colors.red;
    }
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
    bool isSpecial = false,
  }) {
    return AnimatedBuilder(
      animation: isSpecial ? _rotationController : _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (isSpecial ? 0 : _scaleController.value * 0.1),
          child: Transform.rotate(
            angle: isSpecial ? _rotationController.value * 2 * math.pi : 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 24),
                label: Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
