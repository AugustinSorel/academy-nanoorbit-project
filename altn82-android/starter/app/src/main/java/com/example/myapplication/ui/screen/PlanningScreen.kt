package com.example.myapplication.ui.screen

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.myapplication.ui.components.FenetreCard
import com.example.myapplication.ui.viewmodel.NanoOrbitViewModel
import org.koin.androidx.compose.koinViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlanningScreen(
    vm: NanoOrbitViewModel = koinViewModel()
) {
    val fenetres          by vm.filteredFenetres.collectAsState()
    val selectedStation   by vm.selectedStation.collectAsState()
    val stations          by vm.stations.collectAsState()
    val isFenetresLoading by vm.isFenetresLoading.collectAsState()

    val totalDureeMin = fenetres.sumOf { it.duree } / 60
    val totalVolume   = fenetres.mapNotNull { it.volumeDonnees }.sum()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "Planning des communications",
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

            Text(
                "Station sol",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(4.dp))
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(vertical = 4.dp)
            ) {
                item {
                    FilterChip(
                        selected = selectedStation == null,
                        onClick  = { vm.onStationChange(null) },
                        label    = { Text("Toutes") }
                    )
                }
                items(stations) { station ->
                    FilterChip(
                        selected = selectedStation == station.codeStation,
                        onClick  = { vm.onStationChange(station.codeStation) },
                        label    = { Text(station.nomStation) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            if (fenetres.isNotEmpty()) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        "${fenetres.size} fenêtre(s)",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        "Durée : ${totalDureeMin} min | Volume : ${"%.0f".format(totalVolume)} Mo",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Spacer(modifier = Modifier.height(6.dp))
                HorizontalDivider()
                Spacer(modifier = Modifier.height(6.dp))
            }

            PullToRefreshBox(
                isRefreshing = isFenetresLoading,
                onRefresh    = vm::refreshFenetres,
                modifier     = Modifier.fillMaxSize()
            ) {
                if (fenetres.isEmpty()) {
                    Text(
                        "Aucune fenêtre de communication disponible.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 32.dp)
                    )
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        contentPadding = PaddingValues(bottom = 16.dp)
                    ) {
                        items(fenetres, key = { it.idFenetre }) { fenetre ->
                            FenetreCard(
                                fenetre    = fenetre,
                                nomStation = fenetre.nomStation
                                    ?: stations.find { it.codeStation == fenetre.codeStation }?.nomStation
                                    ?: fenetre.codeStation
                            )
                        }
                    }
                }
            }
        }
    }
}
