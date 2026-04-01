# Phase 1

## Dictionnaire des données

### TABLE 1 — ORBITE
Référentiel des plans orbitaux. Une orbite est une entité indépendante ; plusieurs satellites peuvent partager la même orbite (RG-O01).

| ATTRIBUT | TYPE ORACLE | NOT NULL | UNIQUE | PK/FK | EXEMPLE | CONTRAINTES / REMARQUES |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `id_orbite` | VARCHAR2(10) | OUI | OUI | PK | 'ORB-001' | Clé primaire. Format ORB-NNN. Immuable. |
| `type_orbite` | VARCHAR2(10) | OUI | NON | — | 'SSO' | Valeurs autorisées : LEO / MEO / SSO / GEO. Implémenté via CHECK. |
| `altitude` | NUMBER(5) | OUI | NON | — | 550 | Altitude nominale en km. Partie de la contrainte UNIQUE composite (RG-O02). |
| `inclinaison` | NUMBER(5,2) | OUI | NON | — | 97.60 | Angle du plan par rapport à l'équateur (°). UNIQUE composite avec altitude. |
| `periode_orbitale` | NUMBER(6,2) | OUI | NON | — | 95.50 | Durée d'une révolution complète en minutes. |
| `excentricite` | NUMBER(6,4) | OUI | NON | — | 0.0010 | 0 = circulaire, 1 = elliptique extrême. |
| `zone_couverture` | VARCHAR2(200) | OUI | NON | — | 'Polaire globale...' | Description géographique de la zone surveillée. |

> **Notes :** > * Contrainte UNIQUE composite : `(altitude, inclinaison)` — RG-O02.
> * *Données de référence :* ORB-001 (SSO, 550 km), ORB-002 (SSO, 700 km), ORB-003 (LEO, 400 km).

### TABLE 2 — SATELLITE
Parc de CubeSats de NanoOrbit. Chaque satellite est sur exactement une orbite courante (RG-S02).

| ATTRIBUT | TYPE ORACLE | NOT NULL | UNIQUE | PK/FK | EXEMPLE | CONTRAINTES / REMARQUES |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `id_satellite` | VARCHAR2(20) | OUI | OUI | PK | 'SAT-001' | Clé primaire. Format SAT-NNN. Immuable après mise en orbite (RG-S01). |
| `nom_satellite` | VARCHAR2(100) | OUI | NON | — | 'NanoOrbit-Alpha' | Nom commercial ou opérationnel. |
| `date_lancement` | DATE | OUI | NON | — | 2022-03-15 | Date effective de mise en orbite. |
| `masse` | NUMBER(5,2) | OUI | NON | — | 1.30 | Masse au lancement en kilogrammes. |
| `format_cubesat` | VARCHAR2(5) | OUI | NON | — | '3U' | Valeurs autorisées : 1U / 3U / 6U / 12U. CHECK Oracle. |
| `statut` | VARCHAR2(30) | OUI | NON | — | 'Opérationnel' | Valeurs : Opérationnel / En veille / Défaillant / Désorbité. CHECK Oracle. |
| `duree_vie_prevue` | NUMBER(4) | OUI | NON | — | 60 | Durée nominale de la mission en mois. |
| `capacite_batterie`| NUMBER(6,1) | OUI | NON | — | 20 | Énergie stockable par les batteries en Wh. |
| `id_orbite` | VARCHAR2(10) | OUI | NON | FK → ORBITE | 'ORB-001' | Orbite courante du satellite. NOT NULL (RG-S02). ON DELETE RESTRICT. |

> **Notes :** Un satellite "Désorbité" ne peut plus recevoir de fenêtre ni de mission (RG-S06) — géré par trigger.

### TABLE 3 — INSTRUMENT
Catalogue global des instruments embarquables. Un instrument est référencé indépendamment de son affectation (RG-I01) et partageable (RG-I02).

| ATTRIBUT | TYPE ORACLE | NOT NULL | UNIQUE | PK/FK | EXEMPLE | CONTRAINTES / REMARQUES |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `ref_instrument` | VARCHAR2(20) | OUI | OUI | PK | 'INS-CAM-01' | Clé primaire. Référence catalogue constructeur. |
| `type_instrument` | VARCHAR2(50) | OUI | NON | — | 'Caméra optique' | Valeurs : Caméra optique / Infrarouge / Récepteur AIS / Spectromètre. |
| `modele` | VARCHAR2(100) | OUI | NON | — | 'PlanetScope-Mini'| Désignation commerciale de l'instrument. |
| `resolution` | NUMBER(6,1) | NON | NON | — | 3 | Résolution au sol (m). NULL si non applicable (ex. récepteur AIS). |
| `consommation` | NUMBER(5,2) | OUI | NON | — | 2.5 | Puissance consommée en fonctionnement (W). |
| `masse` | NUMBER(5,3) | OUI | NON | — | 0.400 | Masse de l'instrument en kilogrammes. |

### TABLE 4 — EMBARQUEMENT
Table d'association entre `SATELLITE` et `INSTRUMENT`. Porte les attributs propres à chaque couple (RG-S04).

| ATTRIBUT | TYPE ORACLE | NOT NULL | UNIQUE | PK/FK | EXEMPLE | CONTRAINTES / REMARQUES |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `id_satellite` | VARCHAR2(20) | OUI | NON | PK+FK → SATELLITE| 'SAT-001' | Partie de la clé primaire composite. |
| `ref_instrument` | VARCHAR2(20) | OUI | NON | PK+FK → INSTRUMENT| 'INS-CAM-01' | Partie de la clé primaire composite. |
| `date_integration` | DATE | OUI | NON | — | 2022-03-15 | Date à laquelle l'instrument a été intégré. |
| `etat_fonctionnement`| VARCHAR2(20) | OUI | NON | — | 'Nominal' | Valeurs : Nominal / Dégradé / Hors service. CHECK Oracle. |

> **Notes :** Un instrument ne peut pas être simultanément sur deux satellites actifs (RG-I03) — géré par trigger.

### TABLE 5 — CENTRE_CONTROLE
Centres d'opération NanoOrbit. Niveau organisationnel supérieur ; chaque station est rattachée à un centre (RG-G04).

| ATTRIBUT | TYPE ORACLE | NOT NULL | UNIQUE | PK/FK | EXEMPLE | CONTRAINTES / REMARQUES |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `id_centre` | VARCHAR2(10) | OUI | OUI | PK | 'CTR-001' | Clé primaire. Format CTR-NNN. |
| `nom_centre` | VARCHAR2(100) | OUI | NON | — | 'NanoOrbit Paris' | Nom opérationnel du centre. |
| `ville` | VARCHAR2(50) | OUI | NON | — | 'Paris' | Ville d'implantation. |
| `region_geo` | VARCHAR2(50) | OUI | NON | — | 'Europe' | Zone : Europe / Amériques / Asie-Pacifique. |
| `fuseau_horaire` | VARCHAR2(50) | OUI | NON | — | 'Europe/Paris' | Identifiant IANA du fuseau horaire. |
| `statut` | VARCHAR2(20) | OUI | NON | — | 'Actif' | Valeurs : Actif / Inactif. CHECK Oracle. |

### TABLE 6 — STATION_SOL
Antennes au sol mondiales.

| ATTRIBUT | TYPE ORACLE | NOT NULL | UNIQUE | PK/FK | EXEMPLE | CONTRAINTES / REMARQUES |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `code_station` | VARCHAR2(20) | OUI | OUI | PK | 'GS-TLS-01' | Clé primaire. Format GS-XXX-NN. |
| `nom_station` | VARCHAR2(100) | OUI | NON | — | 'Toulouse Station'| Nom opérationnel de la station. |
| `latitude` | NUMBER(9,6) | OUI | NON | — | 43.604700 | Coordonnée géographique Nord/Sud. |
| `longitude` | NUMBER(9,6) | OUI | NON | — | 1.444200 | Coordonnée géographique Est/Ouest. |
| `diametre_antenne` | NUMBER(4,1) | OUI | NON | — | 3.5 | Taille de l'antenne principale en mètres. |
| `bande_frequence` | VARCHAR2(10) | OUI | NON | — | 'S' | Valeurs : UHF / S / X / Ka. CHECK Oracle. |
| `debit_max` | NUMBER(6,1) | OUI | NON | — | 150 | Débit descendant maximal en Mbps. |
| `statut` | VARCHAR2(20) | OUI | NON | — | 'Active' | Valeurs : Active / Maintenance / Inactive. CHECK Oracle. |

> **Notes :** Une station en "Maintenance" ne peut pas créer de nouvelle fenêtre de communication (RG-G03) — Trigger T1.

### TABLE 7 — AFFECTATION_STATION
Rattachement d'une station sol à un centre de contrôle.

| ATTRIBUT | TYPE ORACLE | NOT NULL | UNIQUE | PK/FK | EXEMPLE | CONTRAINTES / REMARQUES |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `id_centre` | VARCHAR2(10) | OUI | NON | PK+FK → CENTRE | 'CTR-001' | Partie de la clé primaire composite. |
| `code_station` | VARCHAR2(20) | OUI | NON | PK+FK → STATION | 'GS-TLS-01' | Partie de la clé primaire composite. |
| `date_affectation`| DATE | OUI | NON | — | 2022-01-10 | Date de prise en charge opérationnelle. |

### TABLE 8 — MISSION
Missions scientifiques de NanoOrbit.

| ATTRIBUT | TYPE ORACLE | NOT NULL | UNIQUE | PK/FK | EXEMPLE | CONTRAINTES / REMARQUES |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `id_mission` | VARCHAR2(20) | OUI | OUI | PK | 'MSN-ARC-2023' | Clé primaire. Format MSN-XXX-AAAA. |
| `nom_mission` | VARCHAR2(100) | OUI | NON | — | 'ArcticWatch 2023'| Intitulé descriptif. |
| `objectif` | VARCHAR2(500) | OUI | NON | — | 'Surveillance...' | Description de l'objectif scientifique. |
| `zone_geo_cible` | VARCHAR2(200) | OUI | NON | — | 'Arctique...' | Région d'intérêt principal. |
| `date_debut` | DATE | OUI | NON | — | 2023-01-01 | Démarrage effectif. NOT NULL (RG-M01). |
| `date_fin` | DATE | NON | NON | — | NULL/2023-05-31 | NULL si active / durée indéterminée. Seul champ nullable. |
| `statut_mission` | VARCHAR2(20) | OUI | NON | — | 'Active' | Valeurs : Active / Terminée. CHECK Oracle. |

> **Notes :** Une mission "Terminée" ne peut plus accueillir de satellites (RG-M04).

### TABLE 9 — FENETRE_COM
Créneaux de communication satellite ↔ station sol.

| ATTRIBUT | TYPE ORACLE | NOT NULL | UNIQUE | PK/FK | EXEMPLE | CONTRAINTES / REMARQUES |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `id_fenetre` | NUMBER | OUI | OUI | PK | 1 | Auto-incrémentée (GENERATED ALWAYS AS IDENTITY). |
| `datetime_debut` | TIMESTAMP | OUI | NON | — | 2024-01-15 09:14 | Début du passage du satellite. |
| `duree` | NUMBER(4) | OUI | NON | — | 420 | Durée en secondes. CHECK : 1 à 900 (RG-F04). |
| `elevation_max` | NUMBER(5,2) | OUI | NON | — | 82.30 | Angle d'élévation maximal du passage (°). |
| `volume_donnees` | NUMBER(8,1) | NON | NON | — | 1250 | Volume téléchargé en Mo. NULL si statut ≠ Réalisée. |
| `statut` | VARCHAR2(20) | OUI | NON | — | 'Réalisée' | Valeurs : Planifiée / Réalisée. CHECK Oracle. |
| `id_satellite` | VARCHAR2(20) | OUI | NON | FK → SATELLITE | 'SAT-001' | NOT NULL (RG-F01). Satellite concerné. |
| `code_station` | VARCHAR2(20) | OUI | NON | FK → STATION_SOL| 'GS-KIR-01' | NOT NULL (RG-F01). Station réceptrice. |

### TABLE 10 — PARTICIPATION
Table d'association entre `SATELLITE` et `MISSION`.

| ATTRIBUT | TYPE ORACLE | NOT NULL | UNIQUE | PK/FK | EXEMPLE | CONTRAINTES / REMARQUES |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `id_satellite` | VARCHAR2(20) | OUI | NON | PK+FK → SATELLITE| 'SAT-001' | Partie de la clé primaire composite. |
| `id_mission` | VARCHAR2(20) | OUI | NON | PK+FK → MISSION | 'MSN-ARC-2023' | Partie de la clé primaire composite. |
| `role_satellite` | VARCHAR2(100) | OUI | NON | — | 'Imageur principal'| Rôle du satellite dans cette mission (RG-M03). |

### TABLE 11 — HISTORIQUE_STATUT
Table de traçabilité alimentée exclusivement par le trigger T5. Aucun INSERT manuel.

| ATTRIBUT | TYPE ORACLE | NOT NULL | UNIQUE | PK/FK | EXEMPLE | CONTRAINTES / REMARQUES |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `id_historique` | NUMBER | OUI | OUI | PK | 1 | Auto-incrémentée (GENERATED ALWAYS AS IDENTITY). |
| `id_satellite` | VARCHAR2(20) | OUI | NON | FK → SATELLITE | 'SAT-004' | Satellite dont le statut a changé. |
| `ancien_statut` | VARCHAR2(30) | OUI | NON | — | 'Opérationnel' | Statut avant la modification (`:OLD.statut`). |
| `nouveau_statut` | VARCHAR2(30) | OUI | NON | — | 'En veille' | Statut après la modification (`:NEW.statut`). |
| `date_changement`| TIMESTAMP | OUI | NON | — | SYSTIMESTAMP | Horodatage automatique de la modification. |
| `motif` | VARCHAR2(200) | NON | NON | — | NULL | Commentaire optionnel sur la raison du changement. |

---

## SECTION 2 — CLASSIFICATION DES RÈGLES DE GESTION

### CATÉGORIE A — Structure relationnelle (PK, FK, UNIQUE)

| CODE | RÈGLE (résumé) | MÉCANISME ORACLE |
| :--- | :--- | :--- |
| **RG-S01** | Identifiant satellite unique, immuable | PK sur `id_satellite` + immuabilité applicative |
| **RG-S02** | Satellite sur une orbite courante | FK NOT NULL `id_orbite` → ORBITE |
| **RG-S03** | 1 à 4 instruments par satellite | Association N-N (EMBARQUEMENT) + CHECK COUNT (procédural) |
| **RG-S04** | Attributs propres à l'embarquement | Entité-association EMBARQUEMENT avec PK composite |
| **RG-S05** | Satellite participe à ≥ 1 mission | Association N-N via PARTICIPATION (card. 1,n côté SATELLITE) |
| **RG-O01** | Orbite indépendante, plusieurs satellites | Entité ORBITE + FK depuis SATELLITE |
| **RG-O02** | Unicité de altitude + inclinaison | UNIQUE (`altitude`, `inclinaison`) dans ORBITE |
| **RG-O03** | Orbite possible sans satellite | FK côté SATELLITE (pas de contrainte inverse) |
| **RG-I01** | Instrument dans un catalogue global | Entité INSTRUMENT indépendante avec PK |
| **RG-I02** | Instrument partageable entre satellites | Association N-N via EMBARQUEMENT |
| **RG-G01** | Station identifiée, localisée | PK `code_station` + NOT NULL latitude/longitude |
| **RG-G02** | Station communique avec plusieurs sat. | Association N-N via FENETRE_COM |
| **RG-G04** | Station rattachée à exactement 1 centre | Table AFFECTATION_STATION avec FK vers CENTRE et STATION |
| **RG-F01** | Fenêtre = 1 satellite + 1 station | FK NOT NULL `id_satellite` + `code_station` dans FENETRE_COM |
| **RG-M01** | Mission : début obligatoire, fin facultative | NOT NULL `date_debut` + nullable `date_fin` |
| **RG-M02** | Mission mobilise ≥ 1 sat, sat dans plusieurs | Association N-N via PARTICIPATION |
| **RG-M03** | Rôle du satellite dans chaque mission | Attribut `role_satellite` dans PARTICIPATION (NOT NULL) |

### CATÉGORIE B — Contrainte simple (CHECK, NOT NULL)

| CODE | RÈGLE (résumé) | MÉCANISME ORACLE |
| :--- | :--- | :--- |
| **(implicite)**| type_orbite ∈ {LEO, MEO, SSO, GEO} | CHECK (`type_orbite` IN ('LEO','MEO','SSO','GEO')) |
| **(implicite)**| format_cubesat ∈ {1U, 3U, 6U, 12U} | CHECK (`format_cubesat` IN ('1U','3U','6U','12U')) |
| **(implicite)**| statut satellite ∈ {Opérationnel, En veille, Défaillant, Désorbité} | CHECK sur `SATELLITE.statut` |
| **(implicite)**| etat_fonctionnement ∈ {Nominal, Dégradé, Hors service} | CHECK sur `EMBARQUEMENT.etat_fonctionnement` |
| **(implicite)**| statut centre ∈ {Actif, Inactif} | CHECK sur `CENTRE_CONTROLE.statut` |
| **(implicite)**| statut station ∈ {Active, Maintenance, Inactive} | CHECK sur `STATION_SOL.statut` |
| **(implicite)**| bande_frequence ∈ {UHF, S, X, Ka} | CHECK sur `STATION_SOL.bande_frequence` |
| **(implicite)**| statut fenêtre ∈ {Planifiée, Réalisée} | CHECK sur `FENETRE_COM.statut` |
| **(implicite)**| statut mission ∈ {Active, Terminée} | CHECK sur `MISSION.statut_mission` |
| **RG-F04** | Durée fenêtre : 1 s ≤ duree ≤ 900 s | CHECK (`duree` BETWEEN 1 AND 900) |

### CATÉGORIE C — Mécanisme procédural (Trigger / Procédure PL/SQL)

| CODE | RÈGLE (résumé) | MÉCANISME ORACLE | TRIGGER |
| :--- | :--- | :--- | :--- |
| **RG-S06** | Sat Désorbité : plus de fenêtre ni mission | Trigger BEFORE INSERT sur FENETRE_COM / PARTICIPATION | T1 + T4 |
| **RG-G03** | Station en Maintenance : pas de nvl fenêtre | Trigger BEFORE INSERT sur FENETRE_COM | T1 (`trg_valider_fenetre`) |
| **RG-F02** | Pas de chevauchement pour un même sat | Trigger BEFORE INSERT OR UPDATE sur FENETRE_COM | T2 (`trg_no_chevauchement`)|
| **RG-F03** | Pas de chevauchement pour une même station| Trigger BEFORE INSERT OR UPDATE sur FENETRE_COM | T2 (`trg_no_chevauchement`)|
| **RG-F05** | volume_donnees NULL si statut ≠ Réalisée | Trigger BEFORE INSERT OR UPDATE sur FENETRE_COM | T3 (`trg_volume_realise`) |
| **RG-M04** | Mission Terminée : plus de nvx satellites | Trigger BEFORE INSERT sur PARTICIPATION | T4 (`trg_mission_terminee`)|
| **RG-S06** | Traçabilité changement statut SATELLITE | Trigger AFTER UPDATE OF statut sur SATELLITE | T5 (`trg_historique_statut`)|
| **RG-I03** | Instrument non simultané sur 2 sat actifs | Trigger BEFORE INSERT sur EMBARQUEMENT (Phase 2) | (à implémenter) |
| **RG-I04** | Instrument HS > 30 j → alerter | Procédure PL/SQL (Phase 3) | Ex.14/15 Phase 3 |

## MCD

![idk](.\mcd.webp)

## MLD

![Texte alternatif](.\mld.png)

## Réflexion sur l'architecture distribuée

### Choix 1 — EMBARQUEMENT : entité-association porteuse d'attributs

**Question :** Comment modéliser le fait qu'un satellite embarque des instruments, sachant que la date d'intégration et l'état de fonctionnement dépendent du **couple** (satellite, instrument) et non de l'un ou l'autre seul ?

**Décision :** `EMBARQUEMENT` est une **entité-association** avec PK composite `(id_satellite, id_instrument)` qui porte les attributs `date_integration` et `etat_fonctionnement`.

**Justification :**
- `date_integration` n'est ni une propriété de SATELLITE (un même satellite peut intégrer plusieurs instruments à des dates différentes), ni de INSTRUMENT (un même modèle peut être intégré sur plusieurs satellites à des dates différentes). Elle appartient uniquement au **fait d'embarquement** du couple (SAT, INS) — c'est une dépendance fonctionnelle vers la PK composite.
- `etat_fonctionnement` décrit l'état **de cet instrument sur ce satellite précis** : INS-IR-01 est « Nominal » sur SAT-001 mais « Dégradé » sur SAT-004. Placer cet attribut dans INSTRUMENT produirait une anomalie de mise à jour (3NF violée).
- La règle RG-S04 l'impose explicitement : *« ces informations sont propres à cet embarquement spécifique »*.
- En MLD relationnel, cela se traduit par une table d'association à PK composite avec FK ON DELETE RESTRICT vers les deux tables parentes.

---

### Choix 2 — FENETRE_COM : association binaire (SATELLITE, STATION_SOL), pas ternaire

**Question :** La fenêtre de communication implique un satellite, une station sol, et indirectement un centre de contrôle. Faut-il modéliser une association ternaire (SATELLITE, STATION_SOL, CENTRE_CONTROLE) ou une association binaire ?

**Décision :** `FENETRE_COM` est une **association binaire** entre SATELLITE et STATION_SOL.

**Justification :**
- Le centre de contrôle est **déjà déduit** par la table AFFECTATION_STATION : chaque station est rattachée à un centre via `(id_centre, code_station)`. Il n'est donc pas nécessaire de stocker le centre dans FENETRE_COM — cela introduirait une redondance et violerait la 3NF (dépendance transitive `id_fenetre → code_station → id_centre`).
- Une association ternaire ne se justifie que lorsque les trois participants sont indépendants et ne peuvent pas être déduits les uns des autres. Or ici, `code_station` détermine fonctionnellement `id_centre` via AFFECTATION_STATION.
- La règle RG-F01 confirme : *« une fenêtre implique obligatoirement un satellite ET une station »*. Le centre n'est pas mentionné comme donnée directe de la fenêtre.
- En pratique, pour connaître le centre responsable d'une fenêtre, on fait une jointure : `FENETRE_COM → AFFECTATION_STATION → CENTRE_CONTROLE`.

---

### Choix 3 — CENTRE_CONTROLE et AFFECTATION_STATION : table de rattachement explicite

**Question :** Comment modéliser le rattachement d'une station sol à un centre de contrôle ? FK directe dans STATION_SOL, ou table de liaison séparée ?

**Décision :** Table **AFFECTATION_STATION** avec PK composite `(id_centre, code_station)` et attribut `date_affectation`.

**Justification :**
- Le cahier des charges indique que le rattachement est daté (`date_affectation`) : c'est un **fait historique** qui porte lui-même un attribut. Une simple FK `id_centre` dans STATION_SOL ne permettrait pas de conserver cette date ni de gérer un historique de rattachements.
- La règle RG-G04 dit *« chaque station est rattachée à **exactement** un centre »*, mais rien n'interdit qu'une station change de centre au fil du temps (c'est justement l'objet de l'exercice MERGE INTO en Phase 4, Ex.16). La table de liaison permet d'exprimer cela proprement.
- Architecturalement, cette table constitue également la **frontière de distribution** : en Phase 4, la répartition des données par centre de contrôle se fait en partitionnant AFFECTATION_STATION, STATION_SOL et FENETRE_COM par région géographique.

---

## 2. Réponses aux questions Q1–Q4 — Architecture distribuée

---

### Q1 — Quelles tables sont strictement locales à un centre de contrôle ?

| Table | Locale à | Justification |
|---|---|---|
| `FENETRE_COM` | Chaque centre | Une fenêtre de communication est planifiée et exécutée par le centre qui supervise la station concernée. Paris ne gère que les fenêtres de GS-TLS-01 et GS-KIR-01 ; Houston ne gère que celles de GS-SGP-01. Ces données n'ont pas à être partagées en temps réel entre centres. |
| `AFFECTATION_STATION` | Chaque centre | La liste des stations supervisées par un centre est une donnée de configuration locale. Chaque centre connaît ses propres affectations. |
| `STATION_SOL` | Chaque centre (fragment) | Les métadonnées d'une station (coordonnées, débit, statut) sont gérées par le centre responsable. Partager ces données en lecture seule vers les autres centres est suffisant ; les mises à jour restent locales. |

**Raisonnement :** Ces tables ont une dimension opérationnelle et géographique forte. Leur volume d'écriture est concentré sur le centre local (c'est lui qui planifie, modifie, clôture). Les dupliquer sur tous les nœuds engendrerait des conflits de mise à jour sans apporter de valeur métier.

---

### Q2 — Quelles tables doivent être globales ?

| Table | Portée | Mécanisme de synchronisation proposé |
|---|---|---|
| `ORBITE` | Globale (référentiel) | **Réplication en lecture seule** vers chaque centre. Les orbites sont des constantes physiques ; les mises à jour sont rares et initiées uniquement par l'équipe d'ingénierie à Paris HQ. |
| `SATELLITE` | Globale (référentiel) | **Réplication maître-esclave** depuis Paris HQ. Le statut peut changer (changement d'orbite, désorbitage) : les mises à jour se font sur le maître, les centres lisent depuis leur réplique locale. Le trigger T5 (HISTORIQUE_STATUT) tourne sur le maître. |
| `INSTRUMENT` | Globale (catalogue) | **Réplication en lecture seule**. Le catalogue d'instruments ne change que lors de l'intégration de nouveaux modèles. |
| `EMBARQUEMENT` | Globale (configuration) | **Réplication en lecture seule.** La configuration instrumentale d'un satellite est définie avant le lancement et évolue rarement. |
| `MISSION` | Globale (pilotage) | **Réplication maître-esclave** depuis Paris HQ. Plusieurs centres peuvent avoir besoin de connaître les missions actives pour coordonner les fenêtres de communication. |
| `PARTICIPATION` | Globale (pilotage) | Idem MISSION. La liste des satellites par mission est une donnée de pilotage partagée. |
| `CENTRE_CONTROLE` | Globale (annuaire) | **Réplication en lecture seule.** Chaque centre doit connaître les autres centres pour les besoins de backup et de coordination. |

**Mécanismes proposés :**
- **Oracle Advanced Replication / GoldenGate** pour la réplication maître-esclave des tables SATELLITE et MISSION.
- **Matérialized Views avec REFRESH ON DEMAND** pour les tables en lecture seule (ORBITE, INSTRUMENT) : les vues matérialisées locales sont rafraîchies lors de chaque mise à jour du maître.

---

### Q3 — Comment Singapour peut-il planifier des fenêtres si le serveur central est indisponible ?

**Architecture proposée : fragmentation horizontale de FENETRE_COM**

```
FENETRE_COM  →  Fragment Paris    : fenêtres liées à GS-TLS-01 et GS-KIR-01
             →  Fragment Houston  : fenêtres liées à GS-SGP-01 (backup équatorial)
             →  Fragment Singapour: fenêtres liées à GS-SGP-01
```

Le critère de fragmentation horizontale est `code_station` : chaque centre ne stocke et ne gère que les fenêtres des stations qui lui sont affectées (via AFFECTATION_STATION).

**Fonctionnement en mode dégradé (serveur central indisponible) :**
1. Singapour dispose d'une **réplique locale** des tables globales (SATELLITE, ORBITE, MISSION) avec le dernier état synchronisé.
2. Singapour peut **insérer localement** dans son fragment de FENETRE_COM : les triggers T1, T2, T3 s'exécutent sur le nœud local avec les données locales.
3. À la reconnexion, les nouvelles fenêtres sont **synchronisées vers le maître** via un mécanisme de reconciliation (GoldenGate ou DBMS_REPLICATION) avec détection des conflits par timestamp.

**Risque résiduel :** Si le statut d'un satellite change sur le maître pendant la déconnexion (ex. SAT-001 passe à Désorbité), Singapour pourrait planifier une fenêtre invalide. Ce risque est atténué par une **durée de validité maximale** du cache local (ex. 24h) et une alerte opérationnelle en cas de déconnexion prolongée.

---

### Q4 — Quels risques de cohérence identifiez-vous dans ce système multi-sites ?

**Scénario 1 : Mise à jour simultanée du statut d'un satellite depuis deux centres**

- **Situation :** Paris met à jour SAT-003 de « Opérationnel » à « En veille » suite à une anomalie thermique. Simultanément, Singapour, travaillant sur sa réplique locale, insère une fenêtre de communication pour SAT-003 car son cache indique encore « Opérationnel ».
- **Risque :** La fenêtre insérée à Singapour est invalide selon la règle RG-S06 (satellite non opérationnel). Lors de la réconciliation, le trigger T1 local n'a pas pu bloquer l'insertion car la réplique locale était obsolète.
- **Mitigation :** Versionner les enregistrements SATELLITE avec un timestamp `derniere_maj`. Lors de la réconciliation, appliquer une règle *last-write-wins* ou *flag-conflict* pour les champs de statut. Ajouter un contrôle différé dans la procédure de synchronisation qui invalide les fenêtres incompatibles avec le nouveau statut.

**Scénario 2 : Création d'une fenêtre sur la même station depuis deux centres simultanément**

- **Situation :** Houston et Singapour ont tous deux accès (en mode dégradé) aux données de GS-SGP-01. Houston planifie une fenêtre pour SAT-001 à 14h00 ; Singapour planifie une fenêtre pour SAT-003 à 14h05 sur la même station. Les deux insertions passent le trigger T2 localement car elles ne se chevauchent pas individuellement. Mais après réconciliation, les deux fenêtres chevauchent peut-être une troisième qui existait sur le maître.
- **Risque :** Violation de la contrainte RG-F03 (pas de chevauchement pour une même station) découverte uniquement après réconciliation.
- **Mitigation :** Adopter une stratégie de **verrouillage optimiste** sur les créneaux de FENETRE_COM par station (token de réservation de créneau). En pratique, chaque centre demande un « verrou de créneau » au maître avant d'insérer localement, avec un timeout configurable. Si le maître est inaccessible, seuls les créneaux existants dans le cache local peuvent être utilisés (pas de nouvelles planifications sur des stations partagées).