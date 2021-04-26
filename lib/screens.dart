import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'helpers.dart';

String lungo2(int n) => n > 9 ? "$n" : "0$n";

String formattaData(String d) {
  DateTime date = DateTime.parse(d);
  return "${lungo2(date.day)}/${lungo2(date.month)}/${date.year}";
}

String tempoPassato(DateTime d) {
  int diffSec =
      (DateTime.now().millisecondsSinceEpoch - d.millisecondsSinceEpoch) ~/
          1000;
  if (diffSec < 60)
    return "${diffSec.toInt()}s";
  else if (diffSec < 3600)
    return "${diffSec ~/ 60}m";
  else
    return "${diffSec ~/ 3600}h";
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vaccinazioni Italia"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<VaccinationData>(
            future: getVaccinationData(),
            builder: (context, snapshot) {
              if (snapshot.hasError) throw snapshot.error;
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());
              VaccinationData dati = snapshot.data;
              return Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("In italia ci sono"),
                  Text(
                    "${dati.numeroVaccinati}",
                    style: Theme.of(context).textTheme.headline3,
                  ),
                  Text(
                      "vaccinati (persone che hanno ricevuto entrambe le dosi di vaccino o la prima dose di Johnson&Johnson)."),
                  Divider(),
                  Text("Sono state somministrate"),
                  Text("${dati.dosiSomministrate}",
                      style: Theme.of(context).textTheme.headline4),
                  Text("dosi di vaccino su"),
                  Text("${dati.dosiConsegnate}",
                      style: Theme.of(context).textTheme.headline4),
                  Text("dosi consegnate."),
                  Text(
                      "Ultimo aggiornamento dati: ${tempoPassato(dati.ultimoAggiornamento)} fa"),
                  Divider(),
                  FlatButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  PaginaConsegne(dati.ultimeConsegne))),
                      child: Text("Ultime consegne vaccini")),
                  FlatButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  PaginaRegioni(dati.datiRegioni))),
                      child: Text("Dati per ogni regione")),
                  FlatButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  PaginaDatiGiorni(dati.datiGiorni))),
                      child: Text("Dati giorno per giorno")),
                  Divider(),
                  FlatButton(
                      onPressed: () {
                        launch(
                            "https://github.com/italia/covid19-opendata-vaccini");
                      },
                      child: Text(
                          "Dati provenienti dagli Open Data del governo italiano.")),
                  FlatButton(
                      onPressed: () {
                        launch("https://github.com/carzacc/vaccitaly");
                      },
                      child: Text(
                          "App 100% FOSS. Clicca qui per raggiungere il codice sorgente."))
                ],
              );
            }),
      ),
    );
  }
}

class PaginaConsegne extends StatelessWidget {
  PaginaConsegne(this.dati);
  final List<Consegna> dati;
  String regione(String area) =>
      area; // TODO: implementare Map che associa aree a regioni
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Ultime consegne vaccino")),
        body: ListView.builder(
          itemCount: dati.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(formattaData(dati[i].data_consegna)),
            subtitle: Text(dati[i].fornitore),
            leading: Text(regione(dati[i].area)),
            trailing: Text("${dati[i].numero_dosi}"),
          ),
        ));
  }
}

class PaginaRegioni extends StatelessWidget {
  PaginaRegioni(this.dati);
  final List<DatiRegione> dati;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dati per ogni regione")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: dati.length,
                itemBuilder: (context, i) => ListTile(
                      leading: Text(dati[i].area),
                      title: Text("${dati[i].vaccinati} vaccinati"),
                      subtitle: Text(
                          "${dati[i].dosi_somministrate}/${dati[i].dosi_consegnate} dosi somministrate(${dati[i].percentuale_somministrazione}%)"),
                    )),
          ),
        ],
      ),
    );
  }
}

class PaginaDatiGiorni extends StatelessWidget {
  PaginaDatiGiorni(this.dati);

  final List<DatiGiornata> dati;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cronologia giornaliera"),
      ),
      body: Column(
        children: [
          Text(
              "Clicca su uno dei giorni per visualizzare i dati divisi per regione"),
          Expanded(
            child: ListView.builder(
                itemCount: dati.length,
                itemBuilder: (context, i) => ListTile(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PaginaDatiRegioniGiorno(
                                  dati[i].regioni,
                                  formattaData(dati[i].data)))),
                      leading: Text("${formattaData(dati[i].data)}"),
                      title: Text("Vaccinati giornata: ${dati[i].vaccinati}"),
                      subtitle: Text(
                          "Dosi somministrate:${dati[i].dosi_somministrate}, dosi consegnate: ${dati[i].dosi_consegnate}"),
                    )),
          ),
        ],
      ),
    );
  }
}

class PaginaDatiRegioniGiorno extends StatelessWidget {
  PaginaDatiRegioniGiorno(this.dati, this.data);

  final List<DatiRegioneGiornata> dati;
  final String data;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dati $data"),
      ),
      body: ListView.builder(
        itemCount: dati.length,
        itemBuilder: (context, i) => ListTile(
          leading: Text("${dati[i].area}"),
          title: Text("Vaccinati giornata: ${dati[i].vaccinati}"),
          subtitle: Text(
              "Dosi somministrate: ${dati[i].dosi_somministrate}, dosi consegnate: ${dati[i].dosi_consegnate}"),
        ),
      ),
    );
  }
}
