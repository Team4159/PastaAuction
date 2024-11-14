import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

late Set<Item> items;

enum ItemCategory { miscellaneous, vouchers, spirits, art, recreation }

class Item {
  final int id;
  final String name;
  final ItemCategory category;
  final List<Widget> images;
  final int msrp, startingbid;

  Item._Item(this.id,
      {required this.name,
      required this.category,
      required this.images,
      required this.msrp,
      required this.startingbid});

  factory Item.fromRecord(Map<String, dynamic> record) {
    if (record
        case {
          'id': int id,
          'name': String name,
          'category': String category,
          'msrp': int msrp,
          'startingbid': int startingbid,
          'images': List<dynamic>? imagenames,
        }) {
      category = category.toLowerCase().replaceAll(" ", "");
      return Item._Item(id,
          name: name,
          category: ItemCategory.values.firstWhere((i) => i.name == category),
          images: [
            if (imagenames != null)
              for (String imagename in imagenames)
                CachedNetworkImage(
                    errorWidget: (context, err, _) => FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Icon(Icons.broken_image_outlined, color: Colors.red[800], size: 96)),
                    progressIndicatorBuilder: (context, _, progress) =>
                        Center(child: CircularProgressIndicator(value: progress.progress)),
                    memCacheHeight: 256,
                    memCacheWidth: 256,
                    maxHeightDiskCache: 512,
                    maxWidthDiskCache: 512,
                    height: 512,
                    width: 512,
                    fit: BoxFit.cover,
                    imageUrl: imagename.startsWith("http")
                        ? imagename
                        : Supabase.instance.client.storage.from("itempics").getPublicUrl(imagename))
          ],
          msrp: msrp,
          startingbid: startingbid);
    }
    throw FormatException("Malformed Item", record);
  }
}

Future<Set<Item>> loadItemList() => Supabase.instance.client
        .from("items")
        .select("*")
        .order("id")
        .withConverter((res) => res.map(Item.fromRecord).toSet())
        .then((il) {
      items = il;
      return il;
    });
