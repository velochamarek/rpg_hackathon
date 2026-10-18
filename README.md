[README.md](https://github.com/user-attachments/files/33614162/README.md)
# Útěk ze simulace

Hackathonová hra. Hráč žije ve fantasy středověkém světě, který je ve skutečnosti simulace. Rozhovory s NPC mění tři parametry a hráč musí najít rovnováhu mezi tím, aby přežil, a tím, aby se ze simulace dostal ven.

---

## Parametry

| Parametr | Start | Rozsah | Význam |
|---|---|---|---|
| **Komfort** | 100 | 0–100 | Životy / síla. Při 0 hráč prohrává. |
| **Glitch** | 0 | 0–100 | Jak blízko je hráč útěku. Při 100 vyhrává. |
| **Reputace** | 50 | 0–100 | Jak hráče berou NPC. Určuje, kdo s ním bude mluvit. |

### Hlavní napětí

- NPC, která dávají **komfort**, chtějí **vysokou reputaci**.
- NPC, která dávají **glitch**, chtějí **nízkou reputaci** a reputaci ještě víc berou.
- Hráč proto musí střídavě reputaci obětovat a znovu si ji budovat.

---

## Pravidla interakce

Hráč klikne na NPC, přečte si úvodní větu a má dvě tlačítka: **akce** nebo **Odejít** (odejít nic nestojí).

Když zvolí akci, stane se vždy toto:

1. **Komfort −2** (každá interakce stojí sílu).
2. Hra zkontroluje **podmínku reputace** dané akce.
3. **Úspěch** → aplikují se efekty a NPC řekne úspěšnou větu.
   **Neúspěch** → nic dalšího, NPC řekne odmítací větu.
4. Hodnoty se oříznou na 0–100 a hra zkontroluje konec.

Výsledek je vždy za **celou interakci**, ne za jednotlivé věty.

---

## Reputační žebřík

NPC jsou ve třech patrech:

- **Město** – dává komfort, chce vysokou reputaci.
- **Okraj** – dostupný vždy, slouží jako cesta zpátky k reputaci.
- **Dno** – dává glitch, bere reputaci.

Když hráč spadne na dno, nemůže rovnou do města. Musí si reputaci nejdřív vybudovat na okraji. Každý pád má tedy jasnou cenu: několik interakcí (a tím komfortu) na cestě zpět.

---

## Prototyp (cca 5 minut)

5 NPC, každé má jednu akci.

| Patro | NPC | Akce | Podmínka | Efekt při úspěchu |
|---|---|---|---|---|
| Město | Obchodnice Běta | Poprosit o jídlo | rep ≥ 40 | komfort +25 |
| Okraj | Rybářka Hana | Pomoct se sítěmi | vždy | rep +15, komfort −10 |
| Okraj | Bard Vítek | Poslechnout zakázanou píseň | rep ≤ 40 | glitch +10, komfort −15 |
| Dno | Prorok Ezechiel | Poslouchat kázání | rep 20–50 | glitch +15, rep −15 |
| Dno | Čarodějnice Morwen | Zaplatit za pravdu | rep ≤ 30 | glitch +30, rep −30, komfort −20 |

K tomu vždy **komfort −2** za interakci.

### Dialogy

**Obchodnice Běta** (Město)
- Úvod: „Dobrý den, poutníku. Vypadáš unaveně.“
- Akce: *Poprosit o jídlo*
- Úspěch: „Na, vezmi si polévku. Pro slušné lidi se tu vždycky něco najde.“
- Neúspěch: „Slyšela jsem, s kým se taháš. Pro takové tu nic nemám.“

**Rybářka Hana** (Okraj)
- Úvod: „Ty sítě se samy nespraví. Nepomůžeš?“
- Akce: *Pomoct se sítěmi*
- Úspěch: „Díky. Řeknu ve městě, že jsi poctivý člověk.“
- Neúspěch: (nenastane, Hana pomoc přijme vždy)

**Bard Vítek** (Okraj)
- Úvod: „Znám jednu píseň, kterou ve městě zpívat nesmím. Chceš ji slyšet?“
- Akce: *Poslechnout zakázanou píseň*
- Úspěch: „…a obloha je jen plátno a slunce je lampa na šňůře…“ Hráčovi se na chvíli rozmaže svět.
- Neúspěch: „Ne, ne. Ty vypadáš, že bys mě udal strážím.“

**Prorok Ezechiel** (Dno)
- Úvod: „Ty! Ty je taky slyšíš? To bzučení za oblohou!“
- Akce: *Poslouchat kázání*
- Úspěch: „Svět je namalovaný. Na okraji lesa bydlí ta, která ví víc. Ale nejdřív tě lidi musí přestat mít rádi.“
- Neúspěch (rep > 50): „Smrdíš městem. Jdi pryč.“
- Neúspěch (rep < 20): „Ty už jsi moc daleko. Nemám ti co říct. Jdi za ní.“

**Čarodějnice Morwen** (Dno)
- Úvod: „Zase jeden, co se chce probudit. Pravda něco stojí.“
- Akce: *Zaplatit za pravdu*
- Úspěch: „Měsíc se neodráží ve studni, protože žádný měsíc není.“ Hráč za pravdu zaplatí svou krví (komfort) a lidé si všimnou jizev (reputace).
- Neúspěch: „Lidé tě ještě mají rádi. S takovým nemluvím.“

### Konce

- **Glitch 100** → výhra: obrazovka „Svět se trhá. Chceš odejít?“ a konec.
- **Komfort 0** → prohra: „Zůstal jsi v simulaci navždy.“

### Ověření balancu

Nejrychlejší vítězná cesta (7 interakcí):

| # | Akce | Komfort | Glitch | Rep |
|---|---|---|---|---|
| – | Start | 100 | 0 | 50 |
| 1 | Ezechiel | 98 | 15 | 35 |
| 2 | Ezechiel | 96 | 30 | 20 |
| 3 | Morwen | 74 | 60 | 0 |
| 4 | Vítek | 57 | 70 | 0 |
| 5 | Hana | 45 | 70 | 15 |
| 6 | Hana | 33 | 70 | 30 |
| 7 | Morwen | 11 | 100 | 0 |

Bezpečnější cesta s jídlem trvá asi 9–10 interakcí. Hráč, který příliš často chodí za Vítkem nebo Morwen a nevrátí se k Bětě, umře. Spamovat jedno NPC nejde: Ezechiel přestane mluvit pod rep 20, Vítek a Morwen bez jídla vyčerpají komfort.

---

## Implementace v Godotu 4

### Scéna (stačí jedna)


Pro dva neúspěšné texty Ezechiela stačí přidat jednoduchou podmínku v `interact` nebo jeden společný text.

### Rozdělení práce (návrh)

- **Programátor:** scéna, skript výše, propojení tlačítek.
- **Grafik:** pozadí vesnice, 5 portrétů NPC, obrazovka konce.
- **Scenárista / tester:** doladí texty, projde hru několikrát a upraví čísla v tabulce.

### Volitelné, pokud zbude čas

- Glitch efekt: shader nebo krátké problikání obrazovky po úspěchu u Vítka, Ezechiela a Morwen.
- Zvuk při změně parametrů.

---

## Plná verze (po hackathonu)

Nápady, které se do prototypu nevešly:

- Víc NPC v každém patře (např. sedlák Matěj na okraji, kněz Anselm ve městě se zpovědí: rep +20, glitch −10 jako rychlá, ale drahá cesta zpět).
- Víc akcí u jednoho NPC.
- Falešný šťastný konec „Zlatá klec“: při velmi vysoké reputaci nabídne purkmistrová hráči pohodlný život v simulaci navždy.
- Finální NPC Architekt, který nabídne útěk.
- Pravidla vztahů mezi parametry pro přesnější výpočty (bude se dále probírat).
