# NanoOrbit Ground Control — Présentation Android

## Table des matières

1. [Fonctionnalités principales](#1-fonctionnalités-principales)
2. [Injection de dépendances — Koin](#2-injection-de-dépendances--koin)
3. [Architecture — MVVM + Repository](#3-architecture--mvvm--repository)
4. [Persistance locale — Room & Cache-First](#4-persistance-locale--room--cache-first)
5. [Chronologie des appels API](#5-chronologie-des-appels-api)

---

## 1. Fonctionnalités principales

### Dashboard — onglet "Satellites"

- Liste de tous les satellites avec `LazyColumn` (rendu paresseux, O(visible) en mémoire vs O(total) pour `Column`)
- Recherche textuelle en temps réel par nom ou orbite
- Filtres par statut via `FilterChip` : Tous / Opérationnel / En veille / Défaillant / Désorbité
- Compteur `{n opérationnels}/{total}` et compteur de résultats de recherche mis à jour en temps réel
- **Pull-to-refresh** : tirer vers le bas recharge les satellites depuis l'API sans perdre la liste existante
- Gestion des états :
  - Chargement initial → `CircularProgressIndicator`
  - Erreur réseau → message + bouton "Réessayer"
  - Liste vide → message contextuel selon les filtres actifs

### Écran Détail

- Chargé à la demande via `GET /satellites/:id` au clic sur un satellite (`LaunchedEffect`)
- 5 sections affichées dans des `Card` :
  1. **Statut** : `StatusBadge`, format CubeSat, type et altitude d'orbite
  2. **Télémétrie** : masse, date de lancement, capacité batterie avec `LinearProgressIndicator` (vert / orange / rouge), durée de vie restante estimée
  3. **Instruments embarqués** : liste des instruments avec type, modèle, résolution, consommation
  4. **Missions** : nom, rôle du satellite, statut de la mission
  5. **Signaler une anomalie** : `AlertDialog` avec saisie libre

### Planning — onglet "Planning"

- Liste des fenêtres de communication triées chronologiquement par `datetimeDebut`
- Sélecteur de station sol par `FilterChip` (toutes les stations ou une station spécifique)
- Indicateurs totaux : nombre de fenêtres, durée cumulée en minutes, volume de données en Mo
- Distinction visuelle des statuts : Planifiée / Réalisée / Annulée
- **Pull-to-refresh** : tirer vers le bas recharge les fenêtres depuis l'API, fonctionne même si la liste est vide

### Carte — onglet "Carte"

- Carte **OpenStreetMap** intégrée via la librairie `osmdroid` (`AndroidView`)
- Stations chargées depuis l'API via le ViewModel (données réelles, pas de mock)
- Marqueurs colorés par statut :
  - Vert `#4CAF50` — Active
  - Orange `#FF9800` — Maintenance
  - Gris `#9E9E9E` — Hors service
- Infobulle au clic : nom de la station, bande de fréquence, débit max
- Mise à jour automatique des marqueurs quand les données changent (recomposition `AndroidView`)
- FAB "Me localiser" : demande la permission GPS à l'exécution et centre la carte sur la position de l'opérateur

---

## 2. Injection de dépendances — Koin

Le graphe de dépendances est déclaré dans `di/AppModule.kt` et démarré dans `NanoOrbitApp.onCreate()`.

```
Retrofit  ──────────────────┐
                             ├──▶  NanoOrbitRepository  ──▶  NanoOrbitViewModel
Room (NanoOrbitDao)  ───────┘
```

| Déclaration Koin | Type | Rôle |
|---|---|---|
| `single { Retrofit }` | Singleton | Client HTTP, configuré avec la stratégie de nommage Oracle |
| `single<NanoOrbitApi>` | Singleton | Interface Retrofit créée à partir du `Retrofit` |
| `single { NanoOrbitDatabase }` | Singleton | Base Room liée au contexte Android |
| `single { dao }` | Singleton | `NanoOrbitDao` extrait de la base Room |
| `single<NanoOrbitRepository>` | Singleton | Reçoit `api` et `dao` par injection |
| `viewModel { NanoOrbitViewModel }` | ViewModel | Cycle de vie géré par Koin, reçoit `repository` |

Dans les composables, `koinViewModel()` résout le ViewModel — aucun passage manuel de paramètre entre écrans.

### Configuration Gson — nommage Oracle

node-oracledb avec `outFormat: OUT_FORMAT_OBJECT` retourne les noms de colonnes en **MAJUSCULES**.
Une `FieldNamingStrategy` personnalisée convertit automatiquement le camelCase Kotlin :

```
idSatellite      →  ID_SATELLITE
nomSatellite     →  NOM_SATELLITE
capaciteBatterie →  CAPACITE_BATTERIE
```

Exception : les clés ajoutées côté JavaScript (`instruments`, `missions`, `recentFenetres`) restent en camelCase et sont gérées avec `@SerializedName` dans `SatelliteDetail`.

---

## 3. Architecture — MVVM + Repository

```
┌─────────────────────────────────────────────┐
│  UI Layer  (Jetpack Compose)                │
│  DashboardScreen / DetailScreen /           │
│  PlanningScreen / MapScreen                 │
│                                             │
│  collectAsState()  ◀──  StateFlow<T>        │
└────────────────────┬────────────────────────┘
                     │ événements (vm::refresh, vm::onSearchQueryChange…)
┌────────────────────▼────────────────────────┐
│  ViewModel  (NanoOrbitViewModel)            │
│                                             │
│  StateFlows exposés :                       │
│    filteredSatellites, isLoading,           │
│    errorMessage, isOffline, lastUpdated,    │
│    searchQuery, selectedStatut,             │
│    operationnelCount,                       │
│    filteredFenetres, isFenetresLoading,     │
│    selectedStation, stations,               │
│    satelliteDetail                          │
│                                             │
│  viewModelScope.launch { }                  │
└────────────────────┬────────────────────────┘
                     │ suspend fun
┌────────────────────▼────────────────────────┐
│  Repository  (NanoOrbitRepository)          │
│                                             │
│  Stratégie Cache-First :                    │
│    1. Lire Room → retour immédiat           │
│    2. Appeler l'API en arrière-plan         │
│    3. Réseau KO + cache non vide            │
│       → retourner cache + isOffline=true    │
│    4. Réseau KO + cache vide                │
│       → propager l'exception                │
│                                             │
│  CacheResult<T>(data, isOffline, lastUpdated)│
└───────┬────────────────────┬────────────────┘
        │                    │
┌───────▼──────┐    ┌────────▼──────────────┐
│  Room        │    │  Retrofit              │
│  NanoOrbitDao│    │  NanoOrbitApi          │
│              │    │                        │
│  satellites  │    │  GET /satellites       │
│  fenetres_com│    │  GET /satellites/:id   │
│              │    │  PATCH /satellites/:id │
│              │    │  GET /fenetres         │
│              │    │  GET /stations         │
│              │    │  GET /missions         │
└──────────────┘    └────────────────────────┘
```

### Validation métier côté client

Miroir des triggers Oracle implémenté dans le Repository :

- **RG-F04** : durée d'une fenêtre de communication limitée à `[1, 900]` secondes — validée avant envoi réseau (`validateFenetreDuree()`)
- **RG-S06** : un satellite désorbité ne peut pas avoir de nouvelles fenêtres — vérification de `satellite.statut == DESORBITE` côté Android, complémentaire au trigger Oracle `T1 (trg_valider_fenetre)`

---

## 4. Persistance locale — Room & Cache-First

### Stratégie Cache-First

À chaque chargement, le Repository suit toujours le même ordre :

```
1. Lire Room immédiatement      →  affichage instantané, même sans réseau
2. Appeler l'API en arrière-plan
   ├── API OK                   →  écraser Room + retourner les données fraîches
   ├── API KO + cache non vide  →  retourner le cache + isOffline = true
   └── API KO + cache vide      →  propager l'erreur (premier lancement sans réseau)
```

Implémentation dans `NanoOrbitRepository` :

```kotlin
val cached = dao.getAllSatellites()          // 1. lecture Room en premier
return try {
    val fresh = /* appels API */
    dao.upsertSatellites(fresh.map { it.toEntity() })  // mise à jour Room
    CacheResult(data = fresh, isOffline = false)
} catch (e: Exception) {
    if (cached.isNotEmpty()) {
        CacheResult(data = cached.toDomain(), isOffline = true)   // 2. fallback cache
    } else {
        throw e                              // 3. rien à afficher
    }
}
```

### Ce qui est mis en cache

#### Table `satellites` — `SatelliteEntity`

Tous les satellites de la constellation, toutes sources API confondues.

| Champ | Source | Nullable |
|---|---|---|
| `idSatellite` | clé primaire | non |
| `nomSatellite`, `formatCubesat`, `capaciteBatterie` | commun | non |
| `statut` | table Oracle `SATELLITE` | oui — absent dans la vue |
| `idOrbite`, `masse`, `dureeViePrevue`, `dateLancement` | table Oracle | oui — absents dans la vue |
| `orbite`, `nbInstruments` | vue `v_satellites_operationnels` | oui — absents dans la table |
| `lastUpdated` | epoch ms de la dernière mise à jour | non |

Les champs sont nullable parce que l'API expose **deux sources** : la vue retourne `orbite` et `nbInstruments`, la table retourne `statut`, `masse`, etc. Room unifie les deux dans une seule table.

#### Table `fenetres_com` — `FenetreEntity`

Seules les **fenêtres des 7 prochains jours** sont conservées :

```kotlin
val sevenDaysAgo = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(7)
val cached = dao.getUpcomingFenetres(sevenDaysAgo)
// SELECT * FROM fenetres_com WHERE datetimeDebut >= :fromEpoch ORDER BY datetimeDebut ASC
```

Champs stockés : `idFenetre`, `datetimeDebut` (epoch ms), `duree` `[1-900]` (RG-F04), `elevationMax`, `volumeDonnees` (nullable si statut ≠ Réalisée — RG-F05), `statut`, `idSatellite`, `codeStation`.

### Ce qui n'est PAS mis en cache

| Donnée | Raison |
|---|---|
| Détail satellite (`GET /satellites/:id`) | Instruments et missions doivent être frais à chaque ouverture de fiche |
| Stations sol | Peu nombreuses — fallback sur `mockStations` si l'API est KO |
| Missions, Orbites | Disponibles dans l'API mais non affichées en liste |

### Ce que voit l'utilisateur hors-ligne

- **Dashboard** : satellites du cache affichés, bannière `isOffline = true` visible
- **Planning** : fenêtres des 7 derniers jours mises en cache disponibles
- **Carte / Détail** : pas de cache → données indisponibles si le réseau est coupé

---

## 5. Chronologie des appels API

### Au démarrage de l'application

```
Application.onCreate()
  └── startKoin { modules(appModule) }
        Koin instancie : Retrofit, NanoOrbitApi, Room, NanoOrbitDao, NanoOrbitRepository

MainActivity → AppNavHost → DashboardScreen
  └── koinViewModel()  →  NanoOrbitViewModel.init {

        loadSatellites()        ← 4 appels lancés EN PARALLÈLE (coroutineScope + async)
          ├── GET /satellites                      (vue v_satellites_operationnels)
          ├── GET /satellites?statut=En veille
          ├── GET /satellites?statut=Défaillant
          └── GET /satellites?statut=Désorbité
              → upsert dans Room
              → _allSatellites mis à jour
              → filteredSatellites recalculé automatiquement (combine)

        loadFenetres()          ← appel unique
          └── GET /fenetres
              → upsert dans Room (fenetres_com)
              → _fenetres mis à jour

        loadStations()          ← appel unique, fallback mock si KO
          └── GET /stations
              → _stations mis à jour
      }
```

### Navigation vers le détail d'un satellite

```
Clic sur SatelliteCard  →  navController.navigate("detail/{id}")
  └── DetailScreen.LaunchedEffect(satelliteId)
        └── GET /satellites/:id
              → _satelliteDetail mis à jour
              → instruments, missions, fenêtres récentes affichés
```

### Actions utilisateur

```
Pull-to-refresh Dashboard   →  refreshSatellites()  →  GET /satellites (×4 parallèle)
Pull-to-refresh Planning    →  refreshFenetres()    →  GET /fenetres
Bouton "Réessayer" (erreur) →  refreshSatellites()  →  GET /satellites (×4 parallèle)
Changement de statut        →  PATCH /satellites/:id/statut
```

### Résumé des routes couvertes

| Méthode | Route | Utilisée par |
|---|---|---|
| `GET` | `/satellites` | Dashboard (×4 statuts en parallèle) |
| `GET` | `/satellites/:id` | DetailScreen |
| `PATCH` | `/satellites/:id/statut` | DetailScreen (bouton statut) |
| `GET` | `/fenetres` | PlanningScreen |
| `GET` | `/stations` | MapScreen + PlanningScreen (chips) |
| `GET` | `/missions` | Repository (disponible, non affiché en liste) |
| `GET` | `/orbites` | Repository (disponible, non affiché en liste) |
