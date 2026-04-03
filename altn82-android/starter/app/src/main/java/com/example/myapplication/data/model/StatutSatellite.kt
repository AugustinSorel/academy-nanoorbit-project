package com.example.myapplication.data.model

import com.google.gson.annotations.SerializedName

/**
 * Enum miroir de la contrainte CHECK Oracle sur SATELLITE.statut_actuel.
 * Valeurs Oracle : 'Opérationnel' | 'En veille' | 'Défaillant' | 'Désorbité'
 *
 * @SerializedName mappe les valeurs French de l'API Oracle vers les constantes Kotlin.
 * Gson respecte ces annotations à la désérialisation, ce qui évite un deserializer custom.
 *
 * Q2 — Pourquoi une enum class plutôt qu'une String libre ?
 * Une enum garantit l'exhaustivité à la compilation : le compilateur Kotlin oblige à traiter
 * tous les cas dans un `when`, ce qu'une String ne peut pas faire. Elle évite aussi les fautes
 * de frappe silencieuses (ex : "Operationnel" vs "Opérationnel") qui passeraient inaperçues
 * avec une String libre mais violeraient la contrainte CHECK Oracle.
 *
 * Q3 — Comment empêcher une fenêtre pour un satellite Désorbité ?
 * Côté Android : vérifier `satellite.statut == StatutSatellite.DESORBITE` avant d'afficher
 * le formulaire de création de fenêtre ; désactiver le bouton et afficher un message d'erreur.
 * Côté Oracle : le trigger T1 (`trg_valider_fenetre`) lève une exception avant INSERT sur
 * FENETRE_COM si le satellite est Désorbité (RG-S06). Les deux mécanismes sont complémentaires :
 * la validation client offre un retour immédiat à l'utilisateur, la validation serveur garantit
 * l'intégrité même en cas d'appel API direct.
 */
enum class StatutSatellite(val displayName: String) {
    @SerializedName("Opérationnel")
    OPERATIONNEL("Opérationnel"),
    @SerializedName("En veille")
    EN_VEILLE("En veille"),
    @SerializedName("Défaillant")
    DEFAILLANT("Défaillant"),
    @SerializedName("Désorbité")
    DESORBITE("Désorbité")
}
