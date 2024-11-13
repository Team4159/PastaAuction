import 'dart:collection' show LinkedHashMap;

import 'package:flutter/material.dart';
import 'package:pastaauction/items.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final topbids = <int, ValueNotifier<Bid>>{}; // fixme needs to be threadsafe

class Bid {
  final int item;
  final String? bidder;
  final int value;

  Bid({required this.item, required this.bidder, required this.value});

  Bid.startingBid(Item item)
      : this.item = item.id,
        this.bidder = null,
        this.value = item.startingbid;

  factory Bid.fromRecord(dynamic record) {
    if (record case {"item": int item, "bidder": String? bidder, "value": int value}) {
      return Bid(item: item, bidder: bidder, value: value);
    }
    throw FormatException("Malformed Bid", record);
  }

  Future<void> submit() => Supabase.instance.client
      .from("bids")
      .insert({"item": item, "bidder": bidder, "value": value});
}

int _counter = 0;
void subscribe(Function onError) {
  _counter++;
  Supabase.instance.client.realtime
      .channel("schema-db-changes")
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: "public",
          table: "bids",
          callback: (payload) {
            var oi = payload.eventType == PostgresChangeEvent.insert
                ? null
                : Bid.fromRecord(payload.oldRecord);
            var ni = payload.eventType == PostgresChangeEvent.delete
                ? null
                : Bid.fromRecord(payload.newRecord);

            int? itemid;
            if (ni != null) {
              // Insert & Update
              if (ni.value > (topbids[ni.item]?.value.value ?? double.negativeInfinity)) {
                print("* -> top bid for ${ni.item}");
                topbids << ni;
                return;
              } else if (oi != null && oi == topbids[ni.item]!.value) {
                // Update only
                print("top bid -> underbid for ${ni.item}");
                itemid = ni.item;
                // don't return, continue executing
              } else {
                print("* -> underbid for ${ni.item}");
                return;
              }
            } else {
              // Delete
              oi!;
              if (oi.value < topbids[oi.item]!.value.value) {
                print("underbid -> x for ${oi.item}");
                return;
              } else {
                print("top bid -> x for ${oi.item}");
                itemid = oi.item;
                // don't return, continue executing
              }
            }
            print("bid shakeup for $itemid");
            Supabase.instance.client
                .rpc("getitemtopbid", params: {"itemid": itemid})
                .withConverter(Bid.fromRecord)
                .then((bid) => topbids << bid);
          })
      .subscribe((status, o) {
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        return;
      case RealtimeSubscribeStatus.timedOut:
      case RealtimeSubscribeStatus.closed:
        if (_counter >= 3) continue err;
        return subscribe(onError);
      err:
      default:
        onError(status, o);
        throw RealtimeSubscribeException(status, o);
    }
  });
} // TODO announce

Future<Map<int, Bid>> reloadTopBids() => Supabase.instance.client
        .from("bids")
        .select("*")
        .order("value", ascending: true)
        .withConverter<Map<int, Bid>>(
            (data) => Map.fromEntries(data.map((e) => MapEntry(e["item"], Bid.fromRecord(e)))))
        .then((tbs) {
      for (var tb in tbs.values) topbids << tb;
      return tbs;
    });
void fillStartBids() {
  for (var item in items) {
    if (item.startingbid <= (topbids[item.id]?.value.value ?? -1)) continue;
    topbids << Bid.startingBid(item);
  }
}

Future<Map<int, Bid>> getUserBids(String email) => Supabase.instance.client
    .from("bids")
    .select("*")
    .eq("bidder", email)
    .order("value", ascending: true)
    .withConverter((data) =>
        LinkedHashMap.fromEntries(data.map((e) => MapEntry(e["item"], Bid.fromRecord(e)))));

extension on Map<dynamic, ValueNotifier<Bid>> {
  // Override the bitwise left-shift operator with "create or update valuenotifier"
  void operator <<(Bid newVal) {
    int item = newVal.item;
    if (!containsKey(item))
      this[item] = ValueNotifier(newVal);
    else
      this[item]!.value = newVal;
  }
}
