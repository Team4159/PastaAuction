import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

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
                                      decoration: const InputDecoration(
                                          border: UnderlineInputBorder(), labelText: "Your Email"),
                                      validator: (value) =>
                                          (value?.isEmpty ?? true) ? "Required" : null,
                                      onSaved: (String? email) => email == null
                                          ? prefs.remove("email")
                                          : prefs.setString("email", email))),
                              const SizedBox(width: 20),
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
                                                border: UnderlineInputBorder(),
                                                prefixText: "\$",
                                                labelText: "Bid Amount"),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly
                                            ],
                                            validator: (value) => value == null
                                                ? "Required"
                                                : int.parse(value) >=
                                                        topbids[item.id]!.value.value * bidmargin
                                                    ? null
                                                    : "Bid too low!",
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
                              Supabase.instance.client.from("bids").insert({
                                "item": item.id,
                                "bidderemail": prefs.getString("email"),
                                "value": stupid[true]
                              }).then((value) {
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
