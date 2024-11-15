import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bids.dart';
import '../main.dart';
import '../items.dart' show Item;

const double bidmargin = 1.1;

class BidMenu extends StatelessWidget {
  final Item item;
  final GlobalKey<FormState> _formkey = GlobalKey();
  final Map<bool, int?> stupid = {true: null};
  BidMenu({super.key, required this.item});

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
      widthFactor: MediaQuery.of(context).size.width > 500 ? 0.5 : 1.0,
      child: Dialog(
          alignment: Alignment.center,
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                  key: _formkey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Place Bid", style: Theme.of(context).textTheme.headlineMedium),
                        Text("'${item.name}'", overflow: TextOverflow.ellipsis),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                  flex: 3,
                                  child: TextFormField(
                                      initialValue: prefs.getString("email"),
                                      decoration: const InputDecoration(labelText: "Your Email"),
                                      validator: (value) =>
                                          (value?.isEmpty ?? true) ? "Required" : null,
                                      onSaved: (String? email) => email == null
                                          ? prefs.remove("email")
                                          : prefs.setString("email", email))),
                              const SizedBox(width: 20),
                              if (item.msrp > topbids[item.id]!.value.value)
                                Flexible(
                                    flex: 1,
                                    child: TextField(
                                        readOnly: true,
                                        enableInteractiveSelection: false,
                                        onTap: null,
                                        controller:
                                            TextEditingController(text: item.msrp.toString()),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                            prefixText: r"$",
                                            labelText: "Retail Value",
                                            labelStyle: TextStyle(fontWeight: FontWeight.w500)))),
                              if (item.msrp > topbids[item.id]!.value.value)
                                const SizedBox(width: 15),
                              Flexible(
                                  flex: 1,
                                  child: ListenableBuilder(
                                      listenable: topbids[item.id]!,
                                      builder: (context, _) => TextFormField(
                                            initialValue:
                                                (topbids[item.id]!.value.value * bidmargin)
                                                    .ceil()
                                                    .toString(),
                                            decoration: const InputDecoration(
                                                prefixText: r"$", labelText: "Bid Amount"),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly
                                            ],
                                            validator: (value) {
                                              if (value == null) return "Required";
                                              int v = int.parse(value);
                                              if (v > 2147483647) return "Bid too high!";
                                              if (v < topbids[item.id]!.value.value * bidmargin)
                                                return "Bid too low!";
                                              return null; // "Bid just right!"
                                            },
                                            onSaved: (value) => stupid[true] =
                                                value == null ? null : int.parse(value),
                                          )))
                            ]),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: () {
                              if (!_formkey.currentState!.validate()) return;
                              _formkey.currentState!.save();
                              if (stupid[true] == null) return;
                              Bid(
                                      item: item.id,
                                      bidder: prefs.getString("email"),
                                      value: stupid[true]!)
                                  .submit()
                                  .then((_) {
                                _formkey.currentState!.reset();
                                Navigator.pop(context);
                              }).catchError((e) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(e.toString())));
                              });
                            },
                            child: const Text("Submit Bid"))
                      ])))));
}
