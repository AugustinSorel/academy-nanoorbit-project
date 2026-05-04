package com.example.myapplication.data.model

import com.google.gson.annotations.SerializedName
import java.util.Date
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
    @SerializedName("instruments")    val instruments: List<InstrumentDetail> = emptyList(),
    @SerializedName("missions")       val missions: List<MissionBrief> = emptyList(),
    @SerializedName("recentFenetres") val recentFenetres: List<FenetreDetail> = emptyList()
)

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
