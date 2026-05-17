# -*- coding: utf-8 -*-
"""Inhalt der 10 Lektionen — wird von build_template.py importiert."""

CHAPTERS = [
    ("chapter.01", "Grundlagen", 1),
    ("chapter.02", "Menschen", 2),
    ("chapter.03", "Essen & Trinken", 3),
    ("chapter.04", "Alltag", 4),
]

LESSONS = [
    ("01-01_begruessung",   "lesson.01-01", "chapter.01", "Begrüßungen",          1),
    ("01-02_zahlen",        "lesson.01-02", "chapter.01", "Zahlen 1–10",          2),
    ("02-01_familie",       "lesson.02-01", "chapter.02", "Familie",              1),
    ("02-02_adjektive",     "lesson.02-02", "chapter.02", "Adjektive",            2),
    ("03-01_essen",         "lesson.03-01", "chapter.03", "Essen",                1),
    ("03-02_cafe",          "lesson.03-02", "chapter.03", "Im Café",              2),
    ("04-01_farben",        "lesson.04-01", "chapter.04", "Farben",               1),
    ("04-02_uhrzeit",       "lesson.04-02", "chapter.04", "Wochentage & Tageszeiten", 2),
    ("04-03_verben",        "lesson.04-03", "chapter.04", "Häufige Verben",       3),
    ("04-04_haus",          "lesson.04-04", "chapter.04", "Im Haus",              4),
]

# Spaltenreihenfolge: slug, italiano, deutsch, wortart, artikel, plural,
#                     beispielsatz_it, beispielsatz_de, notiz, suggested
CONTENT = {
"01-01_begruessung": {"vocab": [
["vocab.ciao","ciao","hallo / tschüss","interj","","","Ciao Marco!","Hallo Marco!","","pair"],
["vocab.buongiorno","buongiorno","guten Morgen / guten Tag","interj","","","Buongiorno, signora.","Guten Morgen, Frau.","","pair"],
["vocab.buonasera","buonasera","guten Abend","interj","","","Buonasera a tutti!","Guten Abend zusammen!","","pair"],
["vocab.buonanotte","buonanotte","gute Nacht","interj","","","Buonanotte, mamma.","Gute Nacht, Mama.","","pair"],
["vocab.arrivederci","arrivederci","auf Wiedersehen","interj","","","","","","mc"],
["vocab.grazie","grazie","danke","interj","","","Grazie mille!","Vielen Dank!","","mc"],
["vocab.prego","prego","bitte (Antwort auf Dankeschön)","interj","","","","","","mc"],
["vocab.scusa","scusa","entschuldigung (informell)","interj","","","Scusa, non ho capito.","Entschuldige, ich habe nicht verstanden.","","typing"],
["vocab.si","sì","ja","adv","","","","","","typing"],
["vocab.no","no","nein","adv","","","","","","typing"],
], "sentences": [
["Ciao, mi chiamo Marco.","Hallo, ich heiße Marco.",""],
["Buongiorno! Come stai?","Guten Morgen! Wie geht's?",""],
["Grazie e arrivederci.","Danke und auf Wiedersehen.",""],
]},

"01-02_zahlen": {"vocab": [
["vocab.uno","uno","eins","num","","","Ho un cane.","Ich habe einen Hund.","","pair"],
["vocab.due","due","zwei","num","","","Due caffè, per favore.","Zwei Kaffee, bitte.","","pair"],
["vocab.tre","tre","drei","num","","","Ho tre fratelli.","Ich habe drei Brüder.","","pair"],
["vocab.quattro","quattro","vier","num","","","","","","pair"],
["vocab.cinque","cinque","fünf","num","","","","","","typing"],
["vocab.sei","sei","sechs","num","","","","","auch 'tu sei' = du bist","typing"],
["vocab.sette","sette","sieben","num","","","","","","typing"],
["vocab.otto","otto","acht","num","","","","","","typing"],
["vocab.nove","nove","neun","num","","","","","","mc"],
["vocab.dieci","dieci","zehn","num","","","Ho dieci anni.","Ich bin zehn Jahre alt.","","mc"],
], "sentences": [
["Ho tre mele.","Ich habe drei Äpfel.",""],
["Uno, due, tre, quattro.","Eins, zwei, drei, vier.",""],
["Sono le otto.","Es ist acht Uhr.",""],
]},

"02-01_familie": {"vocab": [
["vocab.madre","madre","Mutter","noun","la","madri","Mia madre è italiana.","Meine Mutter ist Italienerin.","","pair"],
["vocab.padre","padre","Vater","noun","il","padri","Mio padre lavora a Roma.","Mein Vater arbeitet in Rom.","","pair"],
["vocab.fratello","fratello","Bruder","noun","il","fratelli","","","","pair"],
["vocab.sorella","sorella","Schwester","noun","la","sorelle","","","","pair"],
["vocab.figlio","figlio","Sohn","noun","il","figli","","","","mc"],
["vocab.figlia","figlia","Tochter","noun","la","figlie","","","","mc"],
["vocab.nonno","nonno","Großvater","noun","il","nonni","","","","mc"],
["vocab.nonna","nonna","Großmutter","noun","la","nonne","","","","typing"],
["vocab.zio","zio","Onkel","noun","lo","zii","","","","typing"],
["vocab.zia","zia","Tante","noun","la","zie","","","","typing"],
], "sentences": [
["Mia madre è simpatica.","Meine Mutter ist nett.",""],
["Ho un fratello e una sorella.","Ich habe einen Bruder und eine Schwester.",""],
["Mio padre lavora a Roma.","Mein Vater arbeitet in Rom.",""],
]},

"02-02_adjektive": {"vocab": [
["vocab.grande","grande","groß","adj","","","Una casa grande.","Ein großes Haus.","","pair"],
["vocab.piccolo","piccolo","klein","adj","","","Un cane piccolo.","Ein kleiner Hund.","","pair"],
["vocab.bello","bello","schön","adj","","","Che bello!","Wie schön!","","pair"],
["vocab.brutto","brutto","hässlich / schlecht","adj","","","","","","pair"],
["vocab.buono","buono","gut / lecker","adj","","","La pizza è buona.","Die Pizza ist lecker.","","mc"],
["vocab.cattivo","cattivo","schlecht / böse","adj","","","","","","mc"],
["vocab.nuovo","nuovo","neu","adj","","","","","","mc"],
["vocab.vecchio","vecchio","alt","adj","","","","","","typing"],
["vocab.alto","alto","hoch / groß (Person)","adj","","","","","","typing"],
["vocab.basso","basso","niedrig / klein (Person)","adj","","","","","","typing"],
], "sentences": [
["La casa è grande e bella.","Das Haus ist groß und schön.",""],
["Il caffè è molto buono.","Der Kaffee ist sehr gut.",""],
["Marco è alto e Anna è bassa.","Marco ist groß und Anna ist klein.",""],
]},

"03-01_essen": {"vocab": [
["vocab.pane","pane","Brot","noun","il","pani","Voglio del pane.","Ich möchte Brot.","","pair"],
["vocab.acqua","acqua","Wasser","noun","l'","acque","Un'acqua, per favore.","Ein Wasser, bitte.","","pair"],
["vocab.formaggio","formaggio","Käse","noun","il","formaggi","","","","pair"],
["vocab.pasta","pasta","Pasta / Nudeln","noun","la","paste","","","","pair"],
["vocab.pizza","pizza","Pizza","noun","la","pizze","","","","mc"],
["vocab.pomodoro","pomodoro","Tomate","noun","il","pomodori","","","","mc"],
["vocab.mela","mela","Apfel","noun","la","mele","","","","mc"],
["vocab.frutta","frutta","Obst","noun","la","","","","kein Plural üblich","typing"],
["vocab.verdura","verdura","Gemüse","noun","la","verdure","","","","typing"],
["vocab.carne","carne","Fleisch","noun","la","carni","","","","typing"],
], "sentences": [
["Voglio una pizza e un'acqua.","Ich möchte eine Pizza und ein Wasser.",""],
["Mi piace la pasta al pomodoro.","Ich mag Tomaten-Pasta.",""],
["Ho fame, mangio del pane.","Ich habe Hunger, ich esse Brot.",""],
]},

"03-02_cafe": {"vocab": [
["vocab.caffe","caffè","Kaffee / Espresso","noun","il","caffè","Un caffè, per favore.","Einen Kaffee, bitte.","","pair"],
["vocab.cappuccino","cappuccino","Cappuccino","noun","il","cappuccini","","","","pair"],
["vocab.te","tè","Tee","noun","il","tè","","","","pair"],
["vocab.latte","latte","Milch","noun","il","","Un latte caldo.","Eine warme Milch.","kein Plural üblich","pair"],
["vocab.zucchero","zucchero","Zucker","noun","lo","","","","","mc"],
["vocab.biscotto","biscotto","Keks","noun","il","biscotti","","","","mc"],
["vocab.cornetto","cornetto","Croissant","noun","il","cornetti","","","","mc"],
["vocab.conto","conto","Rechnung","noun","il","conti","Il conto, per favore.","Die Rechnung, bitte.","","typing"],
["vocab.cameriere","cameriere","Kellner","noun","il","camerieri","","","","typing"],
["vocab.menu","menu","Speisekarte","noun","il","menu","","","unveränderlich","typing"],
], "sentences": [
["Un caffè e un cornetto, per favore.","Einen Kaffee und ein Croissant, bitte.",""],
["Vorrei vedere il menu.","Ich möchte die Speisekarte sehen.",""],
["Il conto, per favore!","Die Rechnung, bitte!",""],
]},

"04-01_farben": {"vocab": [
["vocab.rosso","rosso","rot","adj","","","Una mela rossa.","Ein roter Apfel.","","pair"],
["vocab.blu","blu","blau","adj","","","Il cielo è blu.","Der Himmel ist blau.","unveränderlich","pair"],
["vocab.verde","verde","grün","adj","","","L'erba è verde.","Das Gras ist grün.","","pair"],
["vocab.giallo","giallo","gelb","adj","","","","","","pair"],
["vocab.bianco","bianco","weiß","adj","","","Vino bianco.","Weißwein.","","mc"],
["vocab.nero","nero","schwarz","adj","","","","","","mc"],
["vocab.grigio","grigio","grau","adj","","","","","","mc"],
["vocab.marrone","marrone","braun","adj","","","","","","typing"],
["vocab.arancione","arancione","orange","adj","","","","","","typing"],
["vocab.viola","viola","lila","adj","","","","","unveränderlich","typing"],
], "sentences": [
["La mia macchina è rossa.","Mein Auto ist rot.",""],
["Il cielo è blu e l'erba è verde.","Der Himmel ist blau und das Gras ist grün.",""],
["Ho una maglia bianca e nera.","Ich habe ein weiß-schwarzes Shirt.",""],
]},

"04-02_uhrzeit": {"vocab": [
["vocab.lunedi","lunedì","Montag","noun","il","","","","","pair"],
["vocab.martedi","martedì","Dienstag","noun","il","","","","","pair"],
["vocab.mercoledi","mercoledì","Mittwoch","noun","il","","","","","pair"],
["vocab.giovedi","giovedì","Donnerstag","noun","il","","","","","pair"],
["vocab.venerdi","venerdì","Freitag","noun","il","","","","","mc"],
["vocab.sabato","sabato","Samstag","noun","il","","","","","mc"],
["vocab.domenica","domenica","Sonntag","noun","la","","","","","mc"],
["vocab.oggi","oggi","heute","adv","","","Oggi è lunedì.","Heute ist Montag.","","typing"],
["vocab.domani","domani","morgen","adv","","","A domani!","Bis morgen!","","typing"],
["vocab.ieri","ieri","gestern","adv","","","","","","typing"],
], "sentences": [
["Oggi è venerdì.","Heute ist Freitag.",""],
["Domani è sabato.","Morgen ist Samstag.",""],
["Ci vediamo lunedì!","Wir sehen uns am Montag!",""],
]},

"04-03_verben": {"vocab": [
["vocab.essere","essere","sein","verb","","","Io sono Marco.","Ich bin Marco.","Hilfsverb","pair"],
["vocab.avere","avere","haben","verb","","","Ho fame.","Ich habe Hunger.","Hilfsverb","pair"],
["vocab.fare","fare","machen / tun","verb","","","Cosa fai?","Was machst du?","","pair"],
["vocab.andare","andare","gehen / fahren","verb","","","Vado a casa.","Ich gehe nach Hause.","","pair"],
["vocab.venire","venire","kommen","verb","","","Vieni qui!","Komm her!","","mc"],
["vocab.mangiare","mangiare","essen","verb","","","Mangio pizza.","Ich esse Pizza.","","mc"],
["vocab.bere","bere","trinken","verb","","","Bevo acqua.","Ich trinke Wasser.","","mc"],
["vocab.parlare","parlare","sprechen","verb","","","Parlo italiano.","Ich spreche Italienisch.","","typing"],
["vocab.vedere","vedere","sehen","verb","","","Ti vedo!","Ich sehe dich!","","typing"],
["vocab.sapere","sapere","wissen / können","verb","","","Non lo so.","Ich weiß es nicht.","","typing"],
], "sentences": [
["Sono italiano e parlo tedesco.","Ich bin Italiener und spreche Deutsch.",""],
["Vado a mangiare una pizza.","Ich gehe eine Pizza essen.",""],
["Vieni a casa mia domani?","Kommst du morgen zu mir nach Hause?",""],
]},

"04-04_haus": {"vocab": [
["vocab.casa","casa","Haus / Zuhause","noun","la","case","Vado a casa.","Ich gehe nach Hause.","","pair"],
["vocab.porta","porta","Tür","noun","la","porte","","","","pair"],
["vocab.finestra","finestra","Fenster","noun","la","finestre","","","","pair"],
["vocab.stanza","stanza","Zimmer","noun","la","stanze","","","","pair"],
["vocab.cucina","cucina","Küche","noun","la","cucine","","","","mc"],
["vocab.bagno","bagno","Bad","noun","il","bagni","","","","mc"],
["vocab.letto","letto","Bett","noun","il","letti","","","","mc"],
["vocab.tavolo","tavolo","Tisch","noun","il","tavoli","","","","typing"],
["vocab.sedia","sedia","Stuhl","noun","la","sedie","","","","typing"],
["vocab.divano","divano","Sofa","noun","il","divani","","","","typing"],
], "sentences": [
["La cucina è grande.","Die Küche ist groß.",""],
["C'è un tavolo e quattro sedie.","Es gibt einen Tisch und vier Stühle.",""],
["Apri la finestra, per favore.","Öffne das Fenster, bitte.",""],
]},
}
