package com.example.myapplication.data.model

import com.google.gson.annotations.SerializedName
import java.util.Date

/**
 * Modèle complet renvoyé par GET /satellites/:id.
 *
 * Contient les données de la table SATELLITE jointe à ORBITE,
 * plus les sous-listes injectées par l'API :
 *   - instruments : jointure EMBARQUEMENT + INSTRUMENT
 *   - missions    : jointure PARTICIPATION + MISSION
 *   - recentFenetres : 10 dernières fenêtres de la table FENETRE_COM
 *
 * Phase 3 — refactoring routes
 */
data class SatelliteDetail(
    val idSatellite: String,
    val nomSatellite: String,
    val dateLancement: Date?,
    val masse: Double?,
    val formatCubesat: String,
    val statut: StatutSatellite?,
    val dureeViePrevue: Int?,
    val capaciteBatterie: Double,
    val idOrbite: String?,
    val typeOrbite: String?,
    val altitude: Double?,
    val inclinaison: Double?,
    val periodeOrbitale: Double?,
    val zoneCouverture: String?,
    // Clés ajoutées côté JavaScript (minuscules/camelCase), pas des colonnes Oracle
    @SerializedName("instruments")    val instruments: List<InstrumentDetail> = emptyList(),
    @SerializedName("missions")       val missions: List<MissionBrief> = emptyList(),
    @SerializedName("recentFenetres") val recentFenetres: List<FenetreDetail> = emptyList()
)

/**
 * Instrument tel que retourné dans la liste instruments de SatelliteDetail.
 * Enrichi des champs EMBARQUEMENT : dateIntegration, etatFonctionnement.
 */
data class InstrumentDetail(
    val refInstrument: String,
    val typeInstrument: String,
    val modele: String,
    val resolution: Double?,
    val consommation: Double,
    val masse: Double,
    val dateIntegration: Date?,
    val etatFonctionnement: String?
)

/**
 * Mission telle que retournée dans la liste missions de SatelliteDetail.
 * Enrichie du rôle du satellite dans la PARTICIPATION.
 */
data class MissionBrief(
    val idMission: String,
    val nomMission: String,
    val statutMission: String?,
    val dateDebut: Date?,
    val dateFin: Date?,
    val roleSatellite: String?
)

/**
 * Fenêtre récente telle que retournée dans recentFenetres de SatelliteDetail.
 */
data class FenetreDetail(
    val idFenetre: Long,
    val datetimeDebut: Date?,
    val duree: Int,
    val elevationMax: Double,
    val volumeDonnees: Double?,
    val statut: String?,
    val codeStation: String?
)
