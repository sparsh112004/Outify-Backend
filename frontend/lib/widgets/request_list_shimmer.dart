import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class RequestListShimmer extends StatelessWidget {
  const RequestListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.surfaceVariant,
          highlightColor: Theme.of(context).colorScheme.surface,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Container(
                height: 16,
                width: 150,
                color: Colors.white,
              ),
              subtitle: Container(
                height: 12,
                width: 100,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
