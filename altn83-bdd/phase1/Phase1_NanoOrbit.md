# PHASE 1 — Conception & Architecture distribuée
## Projet NanoOrbit — ALTN83 Bases de Données Réparties

---

## L1-A : Dictionnaire des données

### Table ORBITE
| Attribut         | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                        |
|------------------|-----------------|:-----------:|:------:|----------------------------------------------------------------|
| id_orbite        | VARCHAR2(20)    | OUI         | OUI    | PK — Code alphanumérique (ex : ORB-SSO-01)                    |
| nom_orbite       | VARCHAR2(100)   | OUI         | NON    | Nom descriptif de l'orbite                                     |
| type_orbite      | VARCHAR2(10)    | OUI         | NON    | CHECK IN ('SSO', 'LEO', 'MEO', 'GEO')                        |
| altitude         | NUMBER(7,2)     | OUI         | NON    | En km — UNIQUE avec inclinaison (RG-O02)                      |
| inclinaison      | NUMBER(5,2)     | OUI         | NON    | En degrés — UNIQUE avec altitude (RG-O02)                     |
| periode          | NUMBER(7,2)     | OUI         | NON    | Période orbitale en minutes                                    |

**Contrainte composite** : UNIQUE(altitude, inclinaison) — RG-O02

### Table SATELLITE
| Attribut           | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                       |
|--------------------|-----------------|:-----------:|:------:|---------------------------------------------------------------|
| id_satellite       | VARCHAR2(20)    | OUI         | OUI    | PK — Code immuable (ex : SAT-001) — RG-S01                   |
| nom_satellite      | VARCHAR2(100)   | OUI         | NON    | Nom du satellite                                               |
| format_cubesat     | VARCHAR2(3)     | OUI         | NON    | CHECK IN ('1U', '3U', '6U', '12U')                           |
| date_lancement     | DATE            | OUI         | NON    | Date de mise en orbite                                         |
| statut_actuel      | VARCHAR2(30)    | OUI         | NON    | CHECK IN ('Opérationnel','En veille','Défaillant','Désorbité')|
| capacite_batterie  | NUMBER(5,2)     | OUI         | NON    | Capacité en Wh                                                 |
| id_orbite          | VARCHAR2(20)    | OUI         | NON    | #FK → ORBITE(id_orbite)                                       |

### Table INSTRUMENT
| Attribut          | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                       |
|-------------------|-----------------|:-----------:|:------:|---------------------------------------------------------------|
| id_instrument     | VARCHAR2(20)    | OUI         | OUI    | PK — Code alphanumérique (ex : INS-MSI-01)                   |
| nom_instrument    | VARCHAR2(100)   | OUI         | NON    | Nom de l'instrument                                            |
| type_instrument   | VARCHAR2(50)    | OUI         | NON    | Type (Caméra multispectrale, Radar SAR, Capteur AIS, etc.)   |
| resolution        | NUMBER(10,2)    | OUI         | NON    | Résolution en mètres (NVL pour capteurs AIS)                  |
| fabricant         | VARCHAR2(100)   | OUI         | NON    | Nom du fabricant                                               |

### Table EMBARQUEMENT (association SATELLITE - INSTRUMENT)
| Attribut              | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                   |
|-----------------------|-----------------|:-----------:|:------:|------------------------------------------------------------|
| id_satellite          | VARCHAR2(20)    | OUI         | NON    | PK composite + #FK → SATELLITE(id_satellite) — RG-S04    |
| id_instrument         | VARCHAR2(20)    | OUI         | NON    | PK composite + #FK → INSTRUMENT(id_instrument) — RG-S04  |
| date_integration      | DATE            | OUI         | NON    | Date de montage de l'instrument sur le satellite           |
| etat_fonctionnement   | VARCHAR2(20)    | OUI         | NON    | CHECK IN ('Actif', 'Dégradé', 'Inactif')                 |

**PK composite** : (id_satellite, id_instrument)

### Table CENTRE_CONTROLE
| Attribut          | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                    |
|-------------------|-----------------|:-----------:|:------:|------------------------------------------------------------|
| id_centre         | VARCHAR2(20)    | OUI         | OUI    | PK — Code alphanumérique (ex : CC-PAR)                    |
| nom_centre        | VARCHAR2(100)   | OUI         | NON    | Nom du centre                                              |
| ville             | VARCHAR2(100)   | OUI         | NON    | Ville d'implantation                                       |
| pays              | VARCHAR2(100)   | OUI         | NON    | Pays                                                       |
| fuseau_horaire    | VARCHAR2(50)    | OUI         | NON    | Fuseau horaire (ex : UTC+1, UTC+8)                        |

### Table STATION_SOL
| Attribut         | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                     |
|------------------|-----------------|:-----------:|:------:|-------------------------------------------------------------|
| id_station       | VARCHAR2(20)    | OUI         | OUI    | PK — Code alphanumérique (ex : GS-TLS-01)                 |
| nom_station      | VARCHAR2(100)   | OUI         | NON    | Nom de la station                                           |
| latitude         | NUMBER(9,6)     | OUI         | NON    | Latitude GPS                                                |
| longitude        | NUMBER(9,6)     | OUI         | NON    | Longitude GPS                                               |
| debit_max        | NUMBER(10,2)    | OUI         | NON    | Débit max en Mbps                                           |
| statut_station   | VARCHAR2(20)    | OUI         | NON    | CHECK IN ('Active', 'Maintenance', 'Inactive')             |

### Table AFFECTATION_STATION (association CENTRE_CONTROLE - STATION_SOL)
| Attribut          | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                    |
|-------------------|-----------------|:-----------:|:------:|------------------------------------------------------------|
| id_centre         | VARCHAR2(20)    | OUI         | NON    | PK composite + #FK → CENTRE_CONTROLE(id_centre)          |
| id_station        | VARCHAR2(20)    | OUI         | NON    | PK composite + #FK → STATION_SOL(id_station)             |
| date_affectation  | DATE            | OUI         | NON    | Date de rattachement de la station au centre               |

**PK composite** : (id_centre, id_station)

### Table MISSION
| Attribut         | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                     |
|------------------|-----------------|:-----------:|:------:|-------------------------------------------------------------|
| id_mission       | VARCHAR2(20)    | OUI         | OUI    | PK — Code alphanumérique (ex : MSN-ARC-2023)              |
| nom_mission      | VARCHAR2(100)   | OUI         | NON    | Nom de la mission scientifique                              |
| date_debut       | DATE            | OUI         | NON    | Date de début de la mission                                 |
| date_fin         | DATE            | NON         | NON    | Nullable — mission en cours si NULL (RG-M01)               |
| statut_mission   | VARCHAR2(20)    | OUI         | NON    | CHECK IN ('Active', 'Terminée', 'Planifiée')              |
| zone_cible       | VARCHAR2(200)   | OUI         | NON    | Zone géographique ciblée                                    |
| objectif         | VARCHAR2(500)   | OUI         | NON    | Description de l'objectif scientifique                      |

### Table FENETRE_COM (relation binaire SATELLITE - STATION_SOL)
| Attribut          | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                    |
|-------------------|-----------------|:-----------:|:------:|------------------------------------------------------------|
| id_fenetre        | VARCHAR2(20)    | OUI         | OUI    | PK — Code alphanumérique (ex : FEN-001)                   |
| id_satellite      | VARCHAR2(20)    | OUI         | NON    | #FK → SATELLITE(id_satellite)                              |
| id_station        | VARCHAR2(20)    | OUI         | NON    | #FK → STATION_SOL(id_station)                              |
| datetime_debut    | TIMESTAMP       | OUI         | NON    | Date et heure précise du début de passage                  |
| duree             | NUMBER(4)       | OUI         | NON    | En secondes — CHECK BETWEEN 1 AND 900 (RG-F04)            |
| statut_fenetre    | VARCHAR2(20)    | OUI         | NON    | CHECK IN ('Planifiée', 'Réalisée', 'Annulée')            |
| volume_donnees    | NUMBER(12,2)    | NON         | NON    | En Mo — Nullable, NULL si non Réalisée (RG-F05)           |

### Table PARTICIPATION (association SATELLITE - MISSION)
| Attribut        | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                      |
|-----------------|-----------------|:-----------:|:------:|--------------------------------------------------------------|
| id_satellite    | VARCHAR2(20)    | OUI         | NON    | PK composite + #FK → SATELLITE(id_satellite) — RG-M03      |
| id_mission      | VARCHAR2(20)    | OUI         | NON    | PK composite + #FK → MISSION(id_mission) — RG-M03          |
| role_satellite  | VARCHAR2(100)   | OUI         | NON    | Rôle du satellite dans la mission (ex : Imageur principal)  |

**PK composite** : (id_satellite, id_mission)

---

### Classification des règles de gestion

#### Règles de structure relationnelle (PK, FK, UNIQUE)
| Réf.    | Règle                                                                     |
|---------|---------------------------------------------------------------------------|
| RG-S01  | Identifiant satellite unique et immuable                                 |
| RG-O02  | Unicité du couple (altitude, inclinaison) dans ORBITE                    |
| RG-S04  | EMBARQUEMENT est une association porteuse entre SATELLITE et INSTRUMENT  |
| RG-M03  | PARTICIPATION est une association porteuse entre SATELLITE et MISSION    |

#### Règles de contrainte simple (CHECK, NOT NULL)
| Réf.    | Règle                                                                     |
|---------|---------------------------------------------------------------------------|
| RG-F04  | Durée d'une fenêtre de communication entre 1 et 900 secondes             |
| RG-M01  | date_fin de MISSION est nullable (mission en cours)                       |
| RG-F05  | volume_donnees est nullable, forcé à NULL si statut != 'Réalisée'        |

#### Règles de mécanisme procédural (Trigger / Procédure)
| Réf.    | Règle                                                                     |
|---------|---------------------------------------------------------------------------|
| RG-S06  | Un satellite Désorbité ne peut plus avoir de fenêtre ni de mission        |
| RG-F02  | Pas de chevauchement de fenêtres pour un même satellite                   |
| RG-F03  | Pas de chevauchement de fenêtres pour une même station                    |
| RG-G03  | Une station en Maintenance ne peut pas recevoir de fenêtre                |
| RG-M04  | Impossible d'ajouter un satellite à une mission Terminée                  |

---

## L1-B : Modèle Conceptuel de Données (MCD)

### Notation MERISE textuelle

```
┌─────────────┐                    ┌─────────────┐
│   ORBITE    │                    │ INSTRUMENT  │
│─────────────│                    │─────────────│
│ id_orbite   │                    │id_instrument│
│ nom_orbite  │                    │nom_instrument│
│ type_orbite │                    │type_instrument│
│ altitude    │                    │ resolution  │
│ inclinaison │                    │ fabricant   │
│ periode     │                    └──────┬──────┘
└──────┬──────┘                           │
       │                                  │ 0,N
       │ 1,1                              │
       │                          ┌───────┴────────┐
┌──────┴──────┐                   │  EMBARQUEMENT  │
│  SATELLITE  │───────────────────│  (association) │
│─────────────│      0,N          │────────────────│
│id_satellite │                   │date_integration│
│nom_satellite│                   │etat_fonctionnem│
│format_cubesat│                  └────────────────┘
│date_lancement│
│statut_actuel │
│capacite_batt.│         ┌─────────────────┐
└──┬─────┬─────┘         │ PARTICIPATION   │
   │     │               │ (association)   │
   │     │      0,N      │─────────────────│
   │     └───────────────│ role_satellite  │
   │                     └────────┬────────┘
   │                              │ 0,N
   │                     ┌────────┴────────┐
   │                     │    MISSION      │
   │                     │─────────────────│
   │                     │ id_mission      │
   │                     │ nom_mission     │
   │                     │ date_debut      │
   │                     │ date_fin        │
   │                     │ statut_mission  │
   │                     │ zone_cible      │
   │ 0,N                 │ objectif        │
   │                     └─────────────────┘
┌──┴──────────────┐
│   FENETRE_COM   │
│  (association)  │──────────── 0,N ──── STATION_SOL
│─────────────────│                     │───────────│
│ id_fenetre      │                     │id_station │
│ datetime_debut  │                     │nom_station│
│ duree           │                     │ latitude  │
│ statut_fenetre  │                     │ longitude │
│ volume_donnees  │                     │ debit_max │
└─────────────────┘                     │statut_stat│
                                        └─────┬─────┘
                                              │ 0,N
┌──────────────────┐                  ┌───────┴────────┐
│ CENTRE_CONTROLE  │──── 1,N ─────────│ AFFECTATION    │
│──────────────────│                  │ _STATION       │
│ id_centre        │                  │(association)   │
│ nom_centre       │                  │────────────────│
│ ville            │                  │date_affectation│
│ pays             │                  └────────────────┘
│ fuseau_horaire   │
└──────────────────┘
```

### Cardinalités détaillées

| Association         | Entité 1         | Card. | Entité 2         | Card. |
|---------------------|------------------|:-----:|------------------|:-----:|
| possède (orbite)    | ORBITE           | 0,N   | SATELLITE        | 1,1   |
| EMBARQUEMENT        | SATELLITE        | 0,N   | INSTRUMENT       | 0,N   |
| PARTICIPATION       | SATELLITE        | 0,N   | MISSION          | 0,N   |
| FENETRE_COM         | SATELLITE        | 0,N   | STATION_SOL      | 0,N   |
| AFFECTATION_STATION | CENTRE_CONTROLE  | 1,N   | STATION_SOL      | 0,N   |

### Justifications des choix de modélisation

**1. FENETRE_COM : relation binaire (et non ternaire)**
La fenêtre de communication est modélisée comme une **association binaire** entre SATELLITE et STATION_SOL, et non comme une association ternaire impliquant CENTRE_CONTROLE. En effet :
- Le centre de contrôle est lié à la station au sol via AFFECTATION_STATION
- Une fenêtre est un événement physique entre un satellite qui passe et une station qui capte le signal
- Le centre de contrôle est déductible par jointure (STATION_SOL → AFFECTATION_STATION → CENTRE_CONTROLE)
- FENETRE_COM possède un identifiant propre (id_fenetre) car elle porte de nombreux attributs, ce qui en fait une **entité-association** promue en entité avec FK vers SATELLITE et STATION_SOL

**2. EMBARQUEMENT : association porteuse (RG-S04)**
L'association porte `date_integration` et `etat_fonctionnement` car un même instrument peut être monté sur différents satellites, et un même satellite peut embarquer plusieurs instruments. L'état de fonctionnement dépend du couple (satellite, instrument).

**3. PARTICIPATION : association porteuse (RG-M03)**
L'association porte `role_satellite` car le rôle d'un satellite varie selon la mission (imageur principal, relais, etc.).

### Contraintes non exprimables dans le MCD
- **RG-S06** : Un satellite Désorbité ne peut plus participer à des fenêtres ni des missions → Trigger
- **RG-F02/F03** : Pas de chevauchement temporel de fenêtres pour un satellite / une station → Trigger
- **RG-G03** : Station en Maintenance ne peut recevoir de fenêtre → Trigger
- **RG-M04** : Impossible d'ajouter un satellite à une mission Terminée → Trigger
- **RG-F05** : volume_donnees forcé à NULL si statut != 'Réalisée' → Trigger

---

## L1-C : Modèle Logique de Données (MLD)

### Notation relationnelle

```
ORBITE (
    id_orbite       VARCHAR2(20)    PK,
    nom_orbite      VARCHAR2(100)   NOT NULL,
    type_orbite     VARCHAR2(10)    NOT NULL  CHECK IN ('SSO','LEO','MEO','GEO'),
    altitude        NUMBER(7,2)     NOT NULL,
    inclinaison     NUMBER(5,2)     NOT NULL,
    periode         NUMBER(7,2)     NOT NULL,
    UNIQUE (altitude, inclinaison)
)

SATELLITE (
    id_satellite       VARCHAR2(20)    PK,
    nom_satellite      VARCHAR2(100)   NOT NULL,
    format_cubesat     VARCHAR2(3)     NOT NULL  CHECK IN ('1U','3U','6U','12U'),
    date_lancement     DATE            NOT NULL,
    statut_actuel      VARCHAR2(30)    NOT NULL  CHECK IN ('Opérationnel','En veille','Défaillant','Désorbité'),
    capacite_batterie  NUMBER(5,2)     NOT NULL,
    #id_orbite         VARCHAR2(20)    NOT NULL  FK → ORBITE(id_orbite)
)

INSTRUMENT (
    id_instrument     VARCHAR2(20)    PK,
    nom_instrument    VARCHAR2(100)   NOT NULL,
    type_instrument   VARCHAR2(50)    NOT NULL,
    resolution        NUMBER(10,2)    NOT NULL,
    fabricant         VARCHAR2(100)   NOT NULL
)

EMBARQUEMENT (
    #id_satellite          VARCHAR2(20)    PK, FK → SATELLITE(id_satellite),
    #id_instrument         VARCHAR2(20)    PK, FK → INSTRUMENT(id_instrument),
    date_integration       DATE            NOT NULL,
    etat_fonctionnement    VARCHAR2(20)    NOT NULL  CHECK IN ('Actif','Dégradé','Inactif')
)

CENTRE_CONTROLE (
    id_centre         VARCHAR2(20)    PK,
    nom_centre        VARCHAR2(100)   NOT NULL,
    ville             VARCHAR2(100)   NOT NULL,
    pays              VARCHAR2(100)   NOT NULL,
    fuseau_horaire    VARCHAR2(50)    NOT NULL
)

STATION_SOL (
    id_station       VARCHAR2(20)    PK,
    nom_station      VARCHAR2(100)   NOT NULL,
    latitude         NUMBER(9,6)     NOT NULL,
    longitude        NUMBER(9,6)     NOT NULL,
    debit_max        NUMBER(10,2)    NOT NULL,
    statut_station   VARCHAR2(20)    NOT NULL  CHECK IN ('Active','Maintenance','Inactive')
)

AFFECTATION_STATION (
    #id_centre        VARCHAR2(20)    PK, FK → CENTRE_CONTROLE(id_centre),
    #id_station       VARCHAR2(20)    PK, FK → STATION_SOL(id_station),
    date_affectation  DATE            NOT NULL
)

MISSION (
    id_mission       VARCHAR2(20)    PK,
    nom_mission      VARCHAR2(100)   NOT NULL,
    date_debut       DATE            NOT NULL,
    date_fin         DATE            -- Nullable (RG-M01)
    statut_mission   VARCHAR2(20)    NOT NULL  CHECK IN ('Active','Terminée','Planifiée'),
    zone_cible       VARCHAR2(200)   NOT NULL,
    objectif         VARCHAR2(500)   NOT NULL
)

FENETRE_COM (
    id_fenetre        VARCHAR2(20)    PK,
    #id_satellite     VARCHAR2(20)    NOT NULL  FK → SATELLITE(id_satellite),
    #id_station       VARCHAR2(20)    NOT NULL  FK → STATION_SOL(id_station),
    datetime_debut    TIMESTAMP       NOT NULL,
    duree             NUMBER(4)       NOT NULL  CHECK (duree BETWEEN 1 AND 900),
    statut_fenetre    VARCHAR2(20)    NOT NULL  CHECK IN ('Planifiée','Réalisée','Annulée'),
    volume_donnees    NUMBER(12,2)    -- Nullable (RG-F05)
)

PARTICIPATION (
    #id_satellite    VARCHAR2(20)    PK, FK → SATELLITE(id_satellite),
    #id_mission      VARCHAR2(20)    PK, FK → MISSION(id_mission),
    role_satellite   VARCHAR2(100)   NOT NULL
)
```

### Vérification 3NF
- **1NF** : Tous les attributs sont atomiques, pas de groupes répétitifs
- **2NF** : Pas de dépendance fonctionnelle partielle — les attributs des tables à PK composite dépendent de la totalité de la clé
- **3NF** : Pas de dépendance transitive — chaque attribut non-clé dépend directement de la PK

### Colonnes candidates à l'indexation
| Table          | Colonne(s)                    | Justification                                      |
|----------------|-------------------------------|---------------------------------------------------|
| SATELLITE      | id_orbite                     | FK très sollicitée (jointures)                    |
| SATELLITE      | statut_actuel                 | Filtres fréquents par statut                      |
| FENETRE_COM    | id_satellite                  | FK — recherche des fenêtres par satellite         |
| FENETRE_COM    | id_station                    | FK — recherche des fenêtres par station           |
| FENETRE_COM    | datetime_debut                | Recherche temporelle, détection chevauchement     |
| PARTICIPATION  | id_satellite, id_mission      | FK — jointures fréquentes                         |
| EMBARQUEMENT   | id_satellite, id_instrument   | FK — jointures fréquentes                         |
| AFFECTATION_STATION | id_centre, id_station    | FK — jointures fréquentes                         |

---

## L1-D : Note de modélisation & Architecture distribuée

### Justification des 3 choix délicats

**1. FENETRE_COM comme relation binaire SATELLITE-STATION_SOL**
La fenêtre de communication est un événement physique lié au passage d'un satellite au-dessus d'une station. Le centre de contrôle n'intervient pas directement dans cet événement : il est rattaché à la station via AFFECTATION_STATION. Une relation ternaire ajouterait de la redondance et compliquerait la gestion de l'intégrité.

**2. EMBARQUEMENT et PARTICIPATION comme associations N:N porteuses**
Ces deux associations portent des attributs qui dépendent du couple et non des entités individuelles. Un instrument peut être actif sur un satellite et inactif sur un autre → `etat_fonctionnement` dépend du couple. De même, le `role_satellite` varie selon la mission.

**3. FORMAT_CUBESAT en VARCHAR2(3) avec CHECK**
Les valeurs possibles (1U, 3U, 6U, 12U) sont alphanumériques. Un NUMBER ne conviendrait pas car "U" fait partie de la valeur. VARCHAR2(3) avec CHECK offre la validation tout en conservant la lisibilité. Une table de référence serait surdimensionnée pour 4 valeurs stables.

---

### Réponses aux questions Q1–Q4 sur l'architecture distribuée

#### Q1 — Tables strictement locales à un centre de contrôle

Les tables **STATION_SOL**, **AFFECTATION_STATION** et **FENETRE_COM** sont locales à chaque centre :
- Chaque centre gère **ses propres stations au sol** (stations physiquement dans sa zone)
- Les **fenêtres de communication** sont planifiées et exécutées par le centre qui contrôle la station réceptrice
- Les **affectations** lient un centre à ses stations
- Ces données n'ont pas vocation à être partagées car chaque centre n'a besoin que des données de ses propres stations pour planifier les passages

#### Q2 — Tables globales et mécanismes de synchronisation

Les tables **ORBITE**, **SATELLITE**, **INSTRUMENT**, **EMBARQUEMENT**, **MISSION** et **PARTICIPATION** doivent être **globales** (accessibles depuis tous les centres) :
- Le référentiel satellite est unique : un satellite passe au-dessus de toutes les zones
- Les missions sont transverses et impliquent des satellites suivis par différents centres
- Les paramètres orbitaux et instruments sont partagés

**Mécanismes proposés** :
- **Réplication synchrone maître-maître** pour SATELLITE (le statut peut être mis à jour depuis n'importe quel centre)
- **Réplication en lecture seule** pour ORBITE, INSTRUMENT, EMBARQUEMENT (données de référence rarement modifiées, mises à jour depuis un site maître unique)
- **Réplication asynchrone** pour MISSION et PARTICIPATION (tolérance à un léger délai)

#### Q3 — Continuité de service en cas de panne du serveur central

Si le serveur central est indisponible, le centre de Singapour peut continuer à planifier grâce à une **fragmentation horizontale** :

- **FENETRE_COM** est fragmentée horizontalement par centre : chaque site détient les fenêtres de ses propres stations
- **SATELLITE** est répliqué localement en lecture (copie locale des paramètres nécessaires)
- Singapour possède une **copie locale en cache** des données globales (ORBITE, SATELLITE) suffisante pour planifier

La **réconciliation** se fait au retour du serveur central : les fenêtres créées localement sont synchronisées et les conflits résolus par horodatage (le dernier écrit gagne) ou par arbitrage métier.

#### Q4 — Risques de cohérence dans un système multi-sites

**Scénario 1 — Mise à jour simultanée du statut satellite** :
Paris détecte un dysfonctionnement et passe SAT-003 en "Défaillant". Au même moment, Houston reçoit une télémétrie positive et le confirme en "Opérationnel". Les deux mises à jour concurrentes créent un conflit : le statut final dépend de l'ordre d'arrivée des réplications. **Risque** : un satellite défaillant pourrait recevoir de nouvelles fenêtres si le statut "Opérationnel" écrase le "Défaillant".

**Scénario 2 — Planification de fenêtres chevauchantes depuis deux centres** :
Paris planifie une fenêtre pour SAT-001 via GS-TLS-01 à 14h00. Singapour, sans avoir reçu cette information (latence réseau), planifie une fenêtre pour le même satellite à 14h05 via GS-KIR-01. Si les fenêtres se chevauchent temporellement pour le même satellite, la contrainte RG-F02 est violée — mais le trigger local de chaque site ne voit pas la fenêtre planifiée sur l'autre site. **Solution** : verrouillage distribué ou validation centralisée des fenêtres avec file d'attente.
