package com.example.myapplication.ui.screen

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.myapplication.data.model.StatutSatellite
import com.example.myapplication.ui.components.SatelliteCard
import com.example.myapplication.ui.theme.MyApplicationTheme
import com.example.myapplication.ui.viewmodel.NanoOrbitViewModel
import org.koin.androidx.compose.koinViewModel

/*
 * Q1 — LazyColumn vs Column
 * LazyColumn ne compose et ne dessine que les éléments visibles à l'écran (fenêtre glissante).
 * Avec 100 satellites, Column composerait tous les items en une seule passe, saturant la mémoire
 * et bloquant l'UI thread lors du premier rendu. LazyColumn maintient une complexité mémoire en
 * O(éléments visibles) au lieu de O(total), quel que soit le nombre d'items dans la liste.
 */

/**
 * Écran principal — Phase 2.
 *
 * Connecté au ViewModel via collectAsStateWithLifecycle (lifecycle-aware).
 * Délègue tous les événements au ViewModel : pas d'appel réseau direct depuis le composable.
 *
 * @param vm               injecté automatiquement par Koin via koinViewModel()
 * @param onSatelliteClick callback de navigation vers DetailScreen (Phase 3)
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    vm: NanoOrbitViewModel = koinViewModel(),
    onSatelliteClick: (String) -> Unit = {}
) {
    val satellites      by vm.filteredSatellites.collectAsState()
    val isLoading       by vm.isLoading.collectAsState()
    val errorMessage    by vm.errorMessage.collectAsState()
    val searchQuery     by vm.searchQuery.collectAsState()
    val selectedStatut  by vm.selectedStatut.collectAsState()

    val totalCount        = satellites.size
    // statut null → vue opérationnelle : tous les items sont opérationnels par définition
    val operationnelCount = satellites.count {
        it.statut == StatutSatellite.OPERATIONNEL || it.statut == null
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "NanoOrbit Ground Control",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            )
        }
    ) { innerPadding ->

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 16.dp)
        ) {

            Spacer(modifier = Modifier.height(12.dp))

            // ── Barre de recherche ──────────────────────────────────────────
            OutlinedTextField(
                value = searchQuery,
                onValueChange = vm::onSearchQueryChange,
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("Rechercher par nom ou orbite…") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Search,
                        contentDescription = "Recherche"
                    )
                },
                singleLine = true,
                shape = MaterialTheme.shapes.medium
            )

            Spacer(modifier = Modifier.height(8.dp))

            // ── Filtres par statut (Phase 2 — Étape 5) ─────────────────────
            // FilterChip "Tous" + un chip par valeur de StatutSatellite.
            // Le chip actif est surligné (selected = true).
            // Le filtre s'applique en combinaison avec la recherche textuelle (dans le ViewModel).
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(vertical = 4.dp)
            ) {
                item {
                    FilterChip(
                        selected = selectedStatut == null,
                        onClick = { vm.onStatutFilterChange(null) },
                        label = { Text("Tous") }
                    )
                }
                items(StatutSatellite.values().toList()) { statut ->
                    FilterChip(
                        selected = selectedStatut == statut,
                        onClick = { vm.onStatutFilterChange(statut) },
                        label = { Text(statut.displayName) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(6.dp))

            // ── Compteur ────────────────────────────────────────────────────
            if (!isLoading && errorMessage == null) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "$operationnelCount/$totalCount satellites opérationnels",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    // Compteur "{n} résultat(s)" mis à jour en temps réel
                    if (searchQuery.isNotBlank() || selectedStatut != null) {
                        Text(
                            text = "$totalCount résultat(s)",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
            }

            // ── États : chargement / erreur / liste ─────────────────────────
            when {
                isLoading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            CircularProgressIndicator(modifier = Modifier.size(48.dp))
                            Spacer(modifier = Modifier.height(12.dp))
                            Text(
                                text = "Chargement de la constellation…",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                errorMessage != null -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.padding(24.dp)
                        ) {
                            Text(
                                text = "⚠ Erreur",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.error
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = errorMessage!!,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            // Bouton Réessayer appelle refreshSatellites() dans le ViewModel
                            Button(onClick = vm::refreshSatellites) {
                                Text("Réessayer")
                            }
                        }
                    }
                }

                satellites.isEmpty() -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = if (searchQuery.isNotBlank() || selectedStatut != null)
                                "Aucun satellite ne correspond aux filtres actifs."
                            else
                                "Aucun satellite disponible.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                else -> {
                    // ── LazyColumn des satellites (cf. Q1 en haut du fichier) ──
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        contentPadding = PaddingValues(bottom = 16.dp)
                    ) {
                        items(
                            items = satellites,
                            key = { it.idSatellite }
                        ) { satellite ->
                            SatelliteCard(
                                satellite = satellite,
                                onClick = { onSatelliteClick(satellite.idSatellite) }
                            )
                        }
                    }
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Preview
// ---------------------------------------------------------------------------

@Preview(showBackground = true, showSystemUi = true)
@Composable
private fun PreviewDashboard() {
    MyApplicationTheme {
        // Preview statique sans Koin.
        // On instancie un repository factice (mock) et un ViewModel directement.
        val fakeDao = object : com.example.myapplication.data.local.NanoOrbitDao {
            override suspend fun getAllSatellites() = emptyList<com.example.myapplication.data.local.SatelliteEntity>()
            override suspend fun getLastUpdated(): Long? = null
            override suspend fun upsertSatellites(satellites: List<com.example.myapplication.data.local.SatelliteEntity>) {}
            override suspend fun getUpcomingFenetres(fromEpoch: Long) = emptyList<com.example.myapplication.data.local.FenetreEntity>()
            override suspend fun upsertFenetres(fenetres: List<com.example.myapplication.data.local.FenetreEntity>) {}
        }
        val fakeRepository = com.example.myapplication.data.repository.NanoOrbitRepository(
            api = object : com.example.myapplication.data.remote.NanoOrbitApi {
                override suspend fun getSatellites(statut: String?) =
                    com.example.myapplication.data.model.mockSatellites
                override suspend fun getSatelliteDetail(id: String) =
                    com.example.myapplication.data.model.SatelliteDetail(
                        idSatellite = id, nomSatellite = id, dateLancement = null,
                        masse = null, formatCubesat = "-", statut = null,
                        dureeViePrevue = null, capaciteBatterie = 0.0,
                        idOrbite = null, typeOrbite = null, altitude = null,
                        inclinaison = null, periodeOrbitale = null, zoneCouverture = null
                    )
                override suspend fun updateSatelliteStatut(id: String, body: Map<String, String>) =
                    emptyMap<String, String>()
                override suspend fun getFenetres(statut: String?, satellite: String?, station: String?) =
                    emptyList<com.example.myapplication.data.model.FenetreCom>()
                override suspend fun getStations(statut: String?) =
                    com.example.myapplication.data.model.mockStations
                override suspend fun getMissions(statut: String?) =
                    emptyList<com.example.myapplication.data.model.Mission>()
                override suspend fun getOrbites() =
                    emptyList<com.example.myapplication.data.model.Orbite>()
            },
            dao = fakeDao
        )
        val vm = NanoOrbitViewModel(repository = fakeRepository)
        DashboardScreen(vm = vm)
    }
}
