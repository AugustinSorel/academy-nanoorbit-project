package com.example.myapplication.data.model

import com.google.gson.annotations.SerializedName
import java.util.Date

/**
 * Modèle domaine d'une fenêtre de communication.
 *
 * Source : vue v_fenetres_detail (GET /fenetres).
 * Le champ statut est nommé statut_fenetre dans la vue Oracle ;
 * @SerializedName assure le mapping sans renommer le champ Kotlin.
 *
 * Les champs nomSatellite, nomStation, bandeFrequence, dureeFormatee, volumeAffiche
 * viennent de la vue enrichie et sont nullable pour compatibilité avec le cache Room
 * (qui stocke uniquement les champs de la table FENETRE_COM de base).
 */
data class FenetreCom(
    val idFenetre: Long,
    val datetimeDebut: Date,
    val duree: Int,                     // secondes [1-900] — RG-F04
    val elevationMax: Double,           // degrés
    val volumeDonnees: Double?,         // Mo, null si statut ≠ Réalisée — RG-F05
    @SerializedName("STATUT_FENETRE")   // alias de la vue v_fenetres_detail (Oracle uppercase)
    val statut: String,                 // Planifiée / Réalisée / Annulée
    val idSatellite: String,            // FK → SATELLITE
    val codeStation: String,            // FK → STATION_SOL

    // ── Champs enrichis de la vue v_fenetres_detail ──────────────────────────
    val nomSatellite: String? = null,
    val nomStation: String? = null,
    val bandeFrequence: String? = null,
    val dureeFormatee: String? = null,  // ex: "7 min 00 s"
    val volumeAffiche: String? = null   // ex: "1 250.0 Mo"
)
