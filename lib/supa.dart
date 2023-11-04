import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ItemCategory {
  technology,
  games,
  entertainment,
  everyday,
  clothing,
  cooking,
  videogames,
  miscellaneous,
  food,
  giftcards,
  unknown
}

typedef Item = ({
  int id,
  String name,
  String? description,
  int msrp,
  ItemCategory category,
  List<Widget> images
});
Future<List<Item>> fetchItems() async {
  var resp = await Supabase.instance.client
      .from("items")
      .select<PostgrestList>("id, name, description, msrp, category, images")
      .order("id");
  List<Item> out = [];
  for (Map<String, dynamic> row in resp) {
    if (row
        case {
          'id': int id,
          'name': String name,
          'description': String? description,
          'msrp': int msrp,
          'category': String category,
          'images': List<dynamic>? imagenames
        }) {
      category = category.toLowerCase().replaceAll(" ", "");
      out.add((
        id: id,
        name: name,
        description: description,
        msrp: msrp,
        category: ItemCategory.values
            .firstWhere((e) => e.name == category, orElse: () => ItemCategory.unknown),
        images: imagenames
                ?.map((imagename) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                        errorWidget: (context, err, _) => Center(
                            child: Icon(Icons.broken_image_outlined, color: Colors.red[800])),
                        progressIndicatorBuilder: (context, _, progress) =>
                            Center(child: CircularProgressIndicator(value: progress.progress)),
                        memCacheHeight: 250,
                        memCacheWidth: 250,
                        maxHeightDiskCache: 500,
                        maxWidthDiskCache: 500,
                        height: 500,
                        width: 500,
                        fit: BoxFit.cover,
                        imageUrl: Supabase.instance.client.storage
                            .from("itempics")
                            .getPublicUrl(imagename))))
                .toList() ??
            []
      ));
    } else {
      throw Exception("Malformed Data Recieved! ${row.map((k, v) => MapEntry(k, v.runtimeType))}");
    }
  }
  return out;
}

typedef Bid = ({String uuid, String email, int value});
Future<Bid> getItemTopBid(int itemid) =>
    Supabase.instance.client.rpc("getitemtopbid", params: {"itemid": itemid}).then((record) => (
          uuid: record["uuid"] as String? ?? "",
          email: record["bidderemail"] as String? ?? "Starting Bid",
          value: record["value"] as int
        ));
Future<Map<int, Bid>> getAllStartBids() => Supabase.instance.client
    .from("items")
    .select<PostgrestList>("id, startingbid")
    .withConverter((data) => Map.fromEntries(data.map((e) =>
        MapEntry<int, Bid>(e["id"], (uuid: "", email: "Starting Bid", value: e["startingbid"])))));
Future<Map<int, Bid>> getAllTopBids() => Supabase.instance.client
    .from("bids")
    .select<PostgrestList>("id, item, bidderemail, value")
    .order("value", ascending: true)
    .withConverter((data) => Map.fromEntries(data.map((e) => MapEntry<int, Bid>(
        e["item"], (uuid: e["id"], email: e["bidderemail"], value: e["value"])))));
Future<Map<int, Bid>> getMyTopBids(String email) =>
    Supabase.instance.client // fetch all of my top bids
        .from("bids")
        .select<PostgrestList>("id, item, bidderemail, value")
        .eq("bidderemail", email)
        .order("value", ascending: true)
        .withConverter((data) => LinkedHashMap.fromEntries(data.map((e) => MapEntry<int, Bid>(
            e["item"], (uuid: e["id"], email: e["bidderemail"], value: e["value"])))));
