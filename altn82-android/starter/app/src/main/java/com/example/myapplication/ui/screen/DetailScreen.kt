package com.example.myapplication.ui.screen

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.myapplication.data.model.StatutSatellite
import com.example.myapplication.data.model.mockInstruments
import com.example.myapplication.ui.components.InstrumentItem
import com.example.myapplication.ui.components.StatusBadge
import com.example.myapplication.ui.viewmodel.NanoOrbitViewModel
import org.koin.androidx.compose.koinViewModel
import java.text.SimpleDateFormat
import java.util.Locale
import kotlin.math.roundToInt

/**
 * Fiche détaillée d'un satellite — Phase 3 (L3-B).
 *
 * 5 sections :
 *   1. Statut    : StatusBadge, format CubeSat, type orbite, altitude
 *   2. Télémétrie: masse, capaciteBatterie (LinearProgressIndicator), durée de vie estimée
 *   3. Instruments embarqués : liste des InstrumentItem
 *   4. Missions actives : liste des participations
 *   5. Bouton "Signaler une anomalie" → AlertDialog
 *
 * @param satelliteId id reçu en paramètre de route (ex : "SAT-001")
 * @param onBack      callback retour vers Dashboard
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DetailScreen(
    satelliteId: String,
    onBack: () -> Unit = {},
    vm: NanoOrbitViewModel = koinViewModel()
) {
    val satellite = vm.getSatelliteById(satelliteId)
    val embarquements = vm.getEmbarquementsForSatellite(satelliteId)
    val missions = vm.getMissionsForSatellite(satelliteId)

    var showAnomalieDialog by remember { mutableStateOf(false) }
    var anomalieText by remember { mutableStateOf("") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = satellite?.nomSatellite ?: satelliteId,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Retour"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            )
        }
    ) { innerPadding ->

        if (satellite == null) {
            Box(
                modifier = Modifier.fillMaxSize().padding(innerPadding),
                contentAlignment = Alignment.Center
            ) {
                Text("Satellite $satelliteId introuvable.")
            }
            return@Scaffold
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {

            // ── Section 1 : Statut ──────────────────────────────────────────
            SectionCard(title = "Statut") {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    StatusBadge(statut = satellite.statut)
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "Format ${satellite.formatCubesat}",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
                Spacer(modifier = Modifier.height(6.dp))
                LabelValue("Orbite", satellite.idOrbite)
            }

            // ── Section 2 : Télémétrie ──────────────────────────────────────
            SectionCard(title = "Télémétrie") {
                LabelValue("Masse", "${satellite.masse} kg")
                LabelValue("Format", satellite.formatCubesat)
                satellite.dateLancement?.let { launch ->
                    val fmt = SimpleDateFormat("dd/MM/yyyy", Locale.FRANCE)
                    LabelValue("Lancement", fmt.format(launch))
                }
                Spacer(modifier = Modifier.height(8.dp))

                // Indicateur visuel de capacité batterie
                val battPct = (satellite.capaciteBatterie / 60.0).coerceIn(0.0, 1.0).toFloat()
                Text(
                    text = "Batterie : ${satellite.capaciteBatterie} Wh",
                    style = MaterialTheme.typography.bodySmall
                )
                LinearProgressIndicator(
                    progress = { battPct },
                    modifier = Modifier.fillMaxWidth().height(8.dp),
                    color = when {
                        battPct > 0.5f -> MaterialTheme.colorScheme.primary
                        battPct > 0.2f -> MaterialTheme.colorScheme.tertiary
                        else           -> MaterialTheme.colorScheme.error
                    }
                )
                Spacer(modifier = Modifier.height(6.dp))

                // Durée de vie restante estimée
                val moisEcoules = satellite.dateLancement?.let { d ->
                    ((System.currentTimeMillis() - d.time) / (1000L * 60 * 60 * 24 * 30)).toInt()
                } ?: 0
                val moisRestants = (satellite.dureeViePrevue - moisEcoules).coerceAtLeast(0)
                LabelValue("Durée de vie prévue", "${satellite.dureeViePrevue} mois")
                LabelValue(
                    label = "Durée restante estimée",
                    value = if (satellite.statut == StatutSatellite.DESORBITE) "N/A (désorbité)"
                            else "$moisRestants mois"
                )
            }

            // ── Section 3 : Instruments embarqués ──────────────────────────
            SectionCard(title = "Instruments embarqués (${embarquements.size})") {
                if (embarquements.isEmpty()) {
                    Text(
                        "Aucun instrument répertorié.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                } else {
                    embarquements.forEachIndexed { index, emb ->
                        val instrument = mockInstruments.find { it.refInstrument == emb.refInstrument }
                        if (instrument != null) {
                            InstrumentItem(
                                instrument = instrument,
                                etatFonctionnement = emb.etatFonctionnement,
                                showDivider = index < embarquements.size - 1
                            )
                        }
                    }
                }
            }

            // ── Section 4 : Missions ────────────────────────────────────────
            SectionCard(title = "Missions (${missions.size})") {
                if (missions.isEmpty()) {
                    Text(
                        "Aucune mission active.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                } else {
                    missions.forEach { (mission, role) ->
                        Column(modifier = Modifier.padding(vertical = 4.dp)) {
                            Text(mission.nomMission, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                            Text("Rôle : $role", style = MaterialTheme.typography.bodySmall)
                            Text("Statut : ${mission.statutMission}", style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }

            // ── Section 5 : Signaler une anomalie ──────────────────────────
            Button(
                onClick = { showAnomalieDialog = true },
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(Icons.Default.Warning, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Signaler une anomalie")
            }
        }
    }

    // ── Dialog de saisie d'anomalie ─────────────────────────────────────────
    if (showAnomalieDialog) {
        AlertDialog(
            onDismissRequest = { showAnomalieDialog = false },
            title = { Text("Signaler une anomalie") },
            text = {
                Column {
                    Text(
                        "Décrivez l'anomalie observée sur ${satellite?.nomSatellite} :",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = anomalieText,
                        onValueChange = { anomalieText = it },
                        placeholder = { Text("Description libre…") },
                        minLines = 3
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        // TODO : envoyer l'anomalie via ViewModel/Repository
                        showAnomalieDialog = false
                        anomalieText = ""
                    },
                    enabled = anomalieText.isNotBlank()
                ) {
                    Text("Envoyer")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAnomalieDialog = false }) {
                    Text("Annuler")
                }
            }
        )
    }
}

// ── Composants internes ──────────────────────────────────────────────────────

@Composable
private fun SectionCard(title: String, content: @Composable () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.height(8.dp))
            content()
        }
    }
}

@Composable
private fun LabelValue(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Medium)
    }
}
