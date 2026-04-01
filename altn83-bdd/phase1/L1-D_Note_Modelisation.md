# L1-D — Note de modélisation
## Projet NanoOrbit · ALTN83 — Bases de données réparties · EFREI 2025-2026

---

## 1. Justification des trois choix de modélisation délicats

---

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