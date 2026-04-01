Voici les réponses basées sur la structure de la BDD :

---

### Q1 — Pourquoi ne peut-on pas créer SATELLITE avant ORBITE ?

La table `SATELLITE` contient une colonne `id_orbite` déclarée comme **FK NOT NULL** qui référence `ORBITE(id_orbite)`. Oracle exige que la table référencée existe **avant** de pouvoir créer une contrainte de clé étrangère vers elle.

Si on tentait de créer `SATELLITE` en premier, le `CONSTRAINT fk_sat_orbite REFERENCES ORBITE(id_orbite)` échouerait car la table `ORBITE` n'existerait pas encore.

**Règle de gestion traduite** : tout satellite est **obligatoirement** rattaché à une orbite dès sa création. Il ne peut pas exister de satellite "orphelin" sans plan orbital — c'est une contrainte d'intégrité référentielle imposée par la cardinalité **1,1** côté SATELLITE dans le MCD (un satellite possède exactement une orbite).

---

### Q2 — RG-S06 peut-elle être vérifiée au niveau DDL seul ?

**Non.** La règle RG-S06 stipule qu'un satellite au statut `'Désorbité'` ne peut plus recevoir de nouvelles fenêtres de communication ni être affecté à une mission. Or :

- La contrainte CHECK ne peut porter que sur les **colonnes de la même ligne** de la même table
- Ici il faudrait, lors d'un `INSERT` dans `FENETRE_COM` ou `PARTICIPATION`, **aller lire le statut** du satellite dans la table `SATELLITE` — c'est une **requête inter-tables**, impossible en CHECK

**Solution proposée** : un **trigger BEFORE INSERT** sur `FENETRE_COM` et `PARTICIPATION` qui effectue un `SELECT statut INTO v_statut FROM SATELLITE WHERE id_satellite = :NEW.id_satellite` et lève une erreur via `RAISE_APPLICATION_ERROR(-20001, '...')` si le statut vaut `'Désorbité'`.

---

### Q3 — Comment implémenter RG-F02 (pas de chevauchement) ? Exprimable en CHECK ?

**Non, ce n'est pas exprimable en CHECK.** Une contrainte CHECK ne peut pas contenir de sous-requête ni accéder à d'autres lignes de la table. Or, détecter un chevauchement nécessite de comparer la nouvelle fenêtre avec **toutes les fenêtres existantes** du même satellite.

**Solution** : un **trigger BEFORE INSERT OR UPDATE** sur `FENETRE_COM` qui vérifie :

```sql
SELECT COUNT(*) INTO v_count
FROM FENETRE_COM
WHERE id_satellite = :NEW.id_satellite
  AND id_fenetre  != :NEW.id_fenetre
  AND datetime_debut < :NEW.datetime_debut + NUMTODSINTERVAL(:NEW.duree, 'SECOND')
  AND datetime_debut + NUMTODSINTERVAL(duree, 'SECOND') > :NEW.datetime_debut;
```

Si `v_count > 0`, deux fenêtres se chevauchent → on bloque avec `RAISE_APPLICATION_ERROR`. La logique est la même pour RG-F03 (chevauchement par station, en filtrant sur `code_station`).

---

### Q4 — Quel type Oracle pour format_cubesat ?

**`VARCHAR2(3)`** avec une contrainte CHECK.

```sql
format_cubesat VARCHAR2(3) NOT NULL
    CONSTRAINT ck_sat_format CHECK (format_cubesat IN ('1U','3U','6U','12U'))
```

**Justification** :
- Les valeurs `1U, 3U, 6U, 12U` sont **alphanumériques** (un chiffre + la lettre "U") → un `NUMBER` ne peut pas stocker le suffixe "U"
- `VARCHAR2(3)` est suffisant : la valeur la plus longue (`12U`) fait 3 caractères
- Le `CHECK` restreint le domaine aux 4 valeurs autorisées, jouant le rôle d'une **énumération**
- Une table de référence séparée serait surdimensionnée pour seulement 4 valeurs stables et normées dans le domaine spatial