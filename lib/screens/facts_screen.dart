import 'package:flutter/material.dart';

class FactItem {
  final String title;
  final String description;
  final String imageUrl; // Online image URL
  final String? personName;

  const FactItem({
    required this.title,
    required this.description,
    required this.imageUrl,
    this.personName,
  });
}

class FactsScreen extends StatefulWidget {
  const FactsScreen({super.key});

  @override
  State<FactsScreen> createState() => _FactsScreenState();
}

class _FactsScreenState extends State<FactsScreen> {
  /// Curated facts about well-known people (stable list).
  final List<FactItem> _facts = const [
    FactItem(
      title: 'Albert Einstein',
      description:
          'Physicist who developed the theory of relativity and reshaped modern physics.',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/d/d3/Albert_Einstein_Head.jpg',
      personName: 'Albert Einstein',
    ),
    FactItem(
      title: 'Marie Curie',
      description:
          'First person to win two Nobel Prizes, pioneering research on radioactivity.',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/7/7e/Marie_Curie_c1920.jpg',
      personName: 'Marie Curie',
    ),
    FactItem(
      title: 'Nelson Mandela',
      description:
          'Anti-apartheid leader and first Black president of South Africa, symbol of reconciliation.',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/02/Nelson_Mandela_1994.jpg/800px-Nelson_Mandela_1994.jpg',
      personName: 'Nelson Mandela',
    ),
    FactItem(
      title: 'Ada Lovelace',
      description:
          'Mathematician often regarded as the first computer programmer for her notes on the Analytical Engine.',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/a/a4/Ada_Lovelace_portrait.jpg',
      personName: 'Ada Lovelace',
    ),
    FactItem(
      title: 'Isaac Newton',
      description:
          'Formulated the laws of motion and universal gravitation, foundational to classical mechanics.',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/d/d9/Sir_Isaac_Newton_%281643-1727%29.jpg',
      personName: 'Isaac Newton',
    ),
    FactItem(
      title: 'Katherine Johnson',
      description:
          'NASA mathematician whose orbital mechanics calculations were critical to early U.S. crewed spaceflights.',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Katherine_Johnson_1983.jpg/800px-Katherine_Johnson_1983.jpg',
      personName: 'Katherine Johnson',
    ),
    FactItem(
      title: 'Mahatma Gandhi',
      description:
          'Leader of India’s nonviolent independence movement against British rule.',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/d/d1/Portrait_Gandhi.jpg',
      personName: 'Mahatma Gandhi',
    ),
    FactItem(
      title: 'Malala Yousafzai',
      description:
          'Education activist and youngest Nobel Prize laureate advocating for girls\' education.',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Malala_Yousafzai_2015.jpg/800px-Malala_Yousafzai_2015.jpg',
      personName: 'Malala Yousafzai',
    ),
    FactItem(
      title: 'Leonardo da Vinci',
      description:
          'Renaissance polymath known for the Mona Lisa, The Last Supper, and visionary scientific sketches.',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/e/e8/Leonardo_da_Vinci_-_presumed_self-portrait_-_WGA12798.jpg',
      personName: 'Leonardo da Vinci',
    ),
    FactItem(
      title: 'Grace Hopper',
      description:
          'Computer scientist and U.S. Navy rear admiral who pioneered compilers and popularized “debugging.”',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/3/37/Commodore_Grace_M._Hopper%2C_USN_%28covered%29.jpg',
      personName: 'Grace Hopper',
    ),
  ];
  int _currentIndex = 0;

  void _showNextFact() {
    if (_facts.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _facts.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fact = _facts[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Did You Know?')),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image section
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      fact.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Person / title
                if (fact.personName != null)
                  Text(
                    fact.personName!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (fact.personName != null) const SizedBox(height: 8),
                Text(
                  fact.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Fact text
                Text(
                  fact.description,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Next button + indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fact ${_currentIndex + 1} of ${_facts.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showNextFact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.navigate_next),
                      label: const Text(
                        'Next fact',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
