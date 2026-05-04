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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.myapplication.data.model.Instrument
import com.example.myapplication.data.model.StatutSatellite
import com.example.myapplication.ui.components.InstrumentItem
import com.example.myapplication.ui.components.StatusBadge
import com.example.myapplication.ui.viewmodel.NanoOrbitViewModel
import org.koin.androidx.compose.koinViewModel
import java.text.SimpleDateFormat
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DetailScreen(
    satelliteId: String,
    onBack: () -> Unit = {},
    vm: NanoOrbitViewModel = koinViewModel()
) {
    val satellite = vm.getSatelliteById(satelliteId)
    val satelliteDetail by vm.satelliteDetail.collectAsState()

    LaunchedEffect(satelliteId) {
        vm.loadSatelliteDetail(satelliteId)
    }

    val detail = satelliteDetail?.takeIf { it.idSatellite == satelliteId }

    var showAnomalieDialog by remember { mutableStateOf(false) }
    var anomalieText by remember { mutableStateOf("") }

    val effectiveStatut = detail?.statut ?: satellite?.statut ?: StatutSatellite.OPERATIONNEL

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = detail?.nomSatellite ?: satellite?.nomSatellite ?: satelliteId,
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

        if (satellite == null && detail == null) {
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

            SectionCard(title = "Statut") {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    StatusBadge(statut = effectiveStatut)
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "Format ${detail?.formatCubesat ?: satellite?.formatCubesat ?: "-"}",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
                Spacer(modifier = Modifier.height(6.dp))
                val orbitLabel = detail?.idOrbite
                    ?: satellite?.idOrbite
                    ?: satellite?.orbite
                    ?: "-"
                LabelValue("Orbite", orbitLabel)
                detail?.typeOrbite?.let { LabelValue("Type d'orbite", it) }
                detail?.altitude?.let { LabelValue("Altitude", "$it km") }
            }

            SectionCard(title = "Télémétrie") {
                val masse = detail?.masse ?: satellite?.masse
                masse?.let { LabelValue("Masse", "$it kg") }

                val formatCubesat = detail?.formatCubesat ?: satellite?.formatCubesat ?: "-"
                LabelValue("Format", formatCubesat)

                val dateLancement = detail?.dateLancement ?: satellite?.dateLancement
                dateLancement?.let { launch ->
                    val fmt = SimpleDateFormat("dd/MM/yyyy", Locale.FRANCE)
                    LabelValue("Lancement", fmt.format(launch))
                }

                Spacer(modifier = Modifier.height(8.dp))

                val capBatt = detail?.capaciteBatterie ?: satellite?.capaciteBatterie ?: 0.0
                val battPct = (capBatt / 60.0).coerceIn(0.0, 1.0).toFloat()
                Text(
                    text = "Batterie : $capBatt Wh",
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

                val dureeViePrevue = detail?.dureeViePrevue ?: satellite?.dureeViePrevue
                if (dureeViePrevue != null) {
                    val moisEcoules = dateLancement?.let { d ->
                        ((System.currentTimeMillis() - d.time) / (1000L * 60 * 60 * 24 * 30)).toInt()
                    } ?: 0
                    val moisRestants = (dureeViePrevue - moisEcoules).coerceAtLeast(0)
                    LabelValue("Durée de vie prévue", "$dureeViePrevue mois")
                    LabelValue(
                        label = "Durée restante estimée",
                        value = if (effectiveStatut == StatutSatellite.DESORBITE)
                            "N/A (désorbité)"
                        else
                            "$moisRestants mois"
                    )
                }
            }

            val instruments = detail?.instruments ?: emptyList()
            SectionCard(title = "Instruments embarqués (${instruments.size})") {
                if (instruments.isEmpty()) {
                    Text(
                        if (detail == null) "Chargement…" else "Aucun instrument répertorié.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                } else {
                    instruments.forEachIndexed { index, instrDetail ->
                        val instrument = Instrument(
                            refInstrument  = instrDetail.refInstrument,
                            typeInstrument = instrDetail.typeInstrument,
                            modele         = instrDetail.modele,
                            resolution     = instrDetail.resolution,
                            consommation   = instrDetail.consommation,
                            masse          = instrDetail.masse
                        )
                        InstrumentItem(
                            instrument          = instrument,
                            etatFonctionnement  = instrDetail.etatFonctionnement ?: "Inconnu",
                            showDivider         = index < instruments.size - 1
                        )
                    }
                }
            }

            val missions = detail?.missions ?: emptyList()
            SectionCard(title = "Missions (${missions.size})") {
                if (missions.isEmpty()) {
                    Text(
                        if (detail == null) "Chargement…" else "Aucune mission active.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                } else {
                    missions.forEach { missionBrief ->
                        Column(modifier = Modifier.padding(vertical = 4.dp)) {
                            Text(
                                missionBrief.nomMission,
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                "Rôle : ${missionBrief.roleSatellite ?: "-"}",
                                style = MaterialTheme.typography.bodySmall
                            )
                            Text(
                                "Statut : ${missionBrief.statutMission ?: "-"}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }

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

    if (showAnomalieDialog) {
        AlertDialog(
            onDismissRequest = { showAnomalieDialog = false },
            title = { Text("Signaler une anomalie") },
            text = {
                Column {
                    Text(
                        "Décrivez l'anomalie observée sur ${detail?.nomSatellite ?: satellite?.nomSatellite} :",
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
