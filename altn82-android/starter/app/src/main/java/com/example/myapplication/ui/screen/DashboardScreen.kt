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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
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
 * Écran principal — liste de tous les satellites avec recherche temps réel.
 *
 * @param vm           injecté automatiquement par Koin via koinViewModel()
 * @param onSatelliteClick callback de navigation vers DetailScreen (Phase 3)
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    vm: NanoOrbitViewModel = koinViewModel(),
    onSatelliteClick: (String) -> Unit = {}
) {
    val satellites     by vm.filteredSatellites.collectAsState()
    val isLoading      by vm.isLoading.collectAsState()
    val errorMessage   by vm.errorMessage.collectAsState()
    val searchQuery    by vm.searchQuery.collectAsState()

    val totalCount         = satellites.size
    val operationnelCount  = satellites.count { it.statut == StatutSatellite.OPERATIONNEL }

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

            Spacer(modifier = Modifier.height(10.dp))

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
                    if (searchQuery.isNotBlank()) {
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
                            Button(onClick = vm::loadSatellites) {
                                Text("Réessayer")
                            }
                        }
                    }
                }

                satellites.isEmpty() && searchQuery.isNotBlank() -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "Aucun satellite trouvé pour « $searchQuery »",
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
        // Preview statique sans Koin : on passe les données directement
        val vm = NanoOrbitViewModel()
        DashboardScreen(vm = vm)
    }
}
