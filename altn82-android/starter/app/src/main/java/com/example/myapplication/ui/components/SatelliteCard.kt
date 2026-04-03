package com.example.myapplication.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.myapplication.data.model.Satellite
import com.example.myapplication.data.model.StatutSatellite
import com.example.myapplication.data.model.mockSatellites
import com.example.myapplication.ui.theme.MyApplicationTheme

/**
 * Carte affichant les informations essentielles d'un satellite.
 *
 * Comportement pour les satellites Désorbités (RG-S06) :
 * - Opacité réduite à 50 % (carte grisée)
 * - Bandeau "DÉSORBITÉ" en surimpression
 * - Interaction toujours cliquable pour consultation de l'historique,
 *   mais le Dashboard devra désactiver la création de fenêtres (miroir trigger T1 Oracle)
 */
@Composable
fun SatelliteCard(
    satellite: Satellite,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isDesorbite = satellite.statut == StatutSatellite.DESORBITE
    val cardAlpha = if (isDesorbite) 0.55f else 1f

    val dotColor = when (satellite.statut) {
        StatutSatellite.OPERATIONNEL -> Color(0xFF4CAF50)
        StatutSatellite.EN_VEILLE    -> Color(0xFFFF9800)
        StatutSatellite.DEFAILLANT   -> Color(0xFFF44336)
        StatutSatellite.DESORBITE    -> Color(0xFF9E9E9E)
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .alpha(cardAlpha)
            .clickable(onClick = onClick),
        elevation = CardDefaults.cardElevation(defaultElevation = if (isDesorbite) 0.dp else 2.dp)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Pastille colorée selon statut
            Box(
                modifier = Modifier
                    .size(12.dp)
                    .background(color = dotColor, shape = CircleShape)
            )

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = satellite.nomSatellite,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.weight(1f)
                    )
                    StatusBadge(statut = satellite.statut)
                }

                Text(
                    text = "${satellite.formatCubesat}  •  ${satellite.idOrbite}  •  ${satellite.idSatellite}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 2.dp)
                )

                // Bandeau DÉSORBITÉ visible uniquement pour ce statut
                if (isDesorbite) {
                    Text(
                        text = "DÉSORBITÉ — Aucune fenêtre ni mission possible (RG-S06)",
                        style = MaterialTheme.typography.labelSmall,
                        color = Color(0xFF9E9E9E),
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Previews
// ---------------------------------------------------------------------------

@Preview(showBackground = true, name = "Satellite Opérationnel")
@Composable
private fun PreviewOperationnel() {
    MyApplicationTheme {
        SatelliteCard(satellite = mockSatellites[0], onClick = {})
    }
}

@Preview(showBackground = true, name = "Satellite En veille")
@Composable
private fun PreviewEnVeille() {
    MyApplicationTheme {
        SatelliteCard(satellite = mockSatellites[2], onClick = {})
    }
}

@Preview(showBackground = true, name = "Satellite Désorbité")
@Composable
private fun PreviewDesorbite() {
    MyApplicationTheme {
        SatelliteCard(satellite = mockSatellites[3], onClick = {})
    }
}
