import 'package:http/http.dart' as http;
import 'package:meta/meta.dart' show required;
import 'consts.dart';

import 'dart:convert' show json;

const List regioni = [
  "ABR",
  "BAS",
  "CAL",
  "CAM",
  "EMR",
  "FVG",
  "LAZ",
  "LIG",
  "LOM",
  "MAR",
  "MOL",
  "PAB",
  "PAT",
  "PIE",
  "PUG",
  "SAR",
  "SIC",
  "TOS",
  "UMB",
  "VDA",
  "VEN"
];

class VaccinationData {
  VaccinationData(
      {@required this.ultimoAggiornamento,
      @required this.numeroVaccinati,
      @required this.dosiSomministrate,
      @required this.dosiConsegnate,
      @required this.ultimeConsegne,
      @required this.datiRegioni,
      @required this.datiGiorni});
  DateTime ultimoAggiornamento;
  int numeroVaccinati;
  int dosiSomministrate;
  int dosiConsegnate;
  List<Consegna> ultimeConsegne;
  List<DatiRegione> datiRegioni;
  List<DatiGiornata> datiGiorni;
}

class Consegna {
  Consegna(this.data_consegna, this.fornitore, this.area, this.numero_dosi);
  String data_consegna;
  String fornitore;
  String area;
  int numero_dosi;
}

class DatiRegione {
  DatiRegione(this.area);
  String area;
  int dosi_consegnate = 0;
  int dosi_somministrate = 0;
  int vaccinati = 0;
  double percentuale_somministrazione = 0.0;
}

class DatiGiornata {
  DatiGiornata(this.data);
  String data;
  int dosi_somministrate = 0;
  int vaccinati = 0;
  int dosi_consegnate = 0;
  List<DatiRegioneGiornata> regioni;
}

class DatiRegioneGiornata {
  DatiRegioneGiornata(this.area);
  String area;
  int dosi_somministrate = 0;
  int vaccinati = 0;
  int dosi_consegnate = 0;
}

Future<VaccinationData> getVaccinationData() async {
  int vaccinati = 0, dosi = 0, consegnate = 0;
  // fetch open data
  List consegneMap = json.decode(await http.read(urlDatiConsegne))["data"];
  List sommarioRegioni =
      json.decode(await http.read(urlDatiVaccinazioniRegioni))["data"];
  List somministrazioniMap =
      json.decode(await http.read(urlSomministrazioni))["data"];
  DateTime ultimo_aggiornamento = DateTime.parse(json
          .decode(await http.read(urlUltimoAggiornamento))[
      "ultimo_aggiornamento"]); // TODO: cache data to local storage and allow for offline usage
  List<DatiGiornata> datiGiorni = [];
  // creazione lista dati regioni totali
  List<DatiRegione> datiRegioni = regioni.map((e) => DatiRegione(e)).toList();
  // calcolo dati regioni totali
  for (var el in sommarioRegioni) {
    int index = regioni.indexOf(el["area"]);
    datiRegioni[index].dosi_consegnate = el["dosi_consegnate"];
    datiRegioni[index].dosi_somministrate = el["dosi_somministrate"];
    datiRegioni[index].percentuale_somministrazione =
        el["percentuale_somministrazione"];
  }
  // elaborazione dati consegne
  List<Consegna> consegne = consegneMap.map((e) {
    // dati totali
    consegnate += e['numero_dosi'];
    // dati per giornata
    int index = datiGiorni.indexWhere((ei) => ei.data == e["data_consegna"]);
    if (index == -1) {
      // crea giornata
      datiGiorni.add(DatiGiornata(e["data_consegna"]));
      index = datiGiorni.length - 1;
      datiGiorni[index].regioni =
          regioni.map((e) => DatiRegioneGiornata(e)).toList();
    }
    datiGiorni[index].dosi_consegnate += e["numero_dosi"];
    datiGiorni[index].regioni[regioni.indexOf(e["area"])].dosi_consegnate +=
        e["numero_dosi"];

    return Consegna(
        e['data_consegna'], e['fornitore'], e['area'], e['numero_dosi']);
  }).toList()
    ..sort((a, b) =>
        DateTime.parse(b.data_consegna).millisecondsSinceEpoch -
        DateTime.parse(a.data_consegna).millisecondsSinceEpoch);

  // elaborazione dati somministrazioni
  for (var el in somministrazioniMap) {
    // dati somministrazioni totali e vaccinati (2a dose/Janssen) per regione
    datiRegioni[regioni.indexOf(el["area"])].vaccinati += el["seconda_dose"];
    if (el["fornitore"] == "Janssen") {
      datiRegioni[regioni.indexOf(el["area"])].vaccinati += el["prima_dose"];
    }
    vaccinati += el["seconda_dose"];
    if (el["fornitore"] == "Janssen") {
      vaccinati += el["prima_dose"];
    }
    dosi += el["prima_dose"] + el["seconda_dose"];
    // dati somministrazioni giorno per giorno
    int index =
        datiGiorni.indexWhere((e) => e.data == el["data_somministrazione"]);
    if (index == -1) {
      // crea giornata
      datiGiorni.add(DatiGiornata(el["data_somministrazione"]));
      index = datiGiorni.length - 1;
      datiGiorni[index].regioni =
          regioni.map((e) => DatiRegioneGiornata(e)).toList();
    }
    // aggiorna dati totali giornata
    datiGiorni[index].vaccinati += el["seconda_dose"];
    datiGiorni[index].dosi_somministrate +=
        el["prima_dose"] + el["seconda_dose"];
    // aggiorna dati regione giornata
    datiGiorni[index].regioni[regioni.indexOf(el["area"])].dosi_somministrate +=
        el["prima_dose"] + el["seconda_dose"];
    datiGiorni[index].regioni[regioni.indexOf(el["area"])].vaccinati +=
        el["seconda_dose"];
    if (el["fornitore"] == "Janssen") {
      datiGiorni[index].vaccinati += el["prima_dose"];
    }
  }
  datiGiorni.sort((a, b) =>
      DateTime.parse(b.data).millisecondsSinceEpoch -
      DateTime.parse(a.data).millisecondsSinceEpoch);
  return VaccinationData(
      datiRegioni: datiRegioni,
      numeroVaccinati: vaccinati,
      dosiSomministrate: dosi,
      ultimoAggiornamento: ultimo_aggiornamento,
      dosiConsegnate: consegnate,
      ultimeConsegne: consegne,
      datiGiorni: datiGiorni);
}
