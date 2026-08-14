import 'package:flutter/material.dart';
import 'uds_chip.dart';

/// Multi-select tag cloud.
class UdsTagSelector extends StatelessWidget {
  const UdsTagSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((tag) {
        final isOn = selected.contains(tag);
        return UdsChip(
          label: tag,
          selected: isOn,
          variant: UdsChipVariant.choice,
          onTap: () {
            final next = Set<String>.from(selected);
            if (isOn) {
              next.remove(tag);
            } else {
              next.add(tag);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}
