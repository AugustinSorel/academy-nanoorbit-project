package com.example.myapplication.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.myapplication.data.model.FenetreCom
import com.example.myapplication.data.model.mockFenetres
import com.example.myapplication.data.model.mockStations
import com.example.myapplication.ui.theme.MyApplicationTheme
import java.text.SimpleDateFormat
import java.util.Locale

/**
 * Carte affichant une fenêtre de communication satellite ↔ station sol.
 *
 * Contrainte RG-F04 (miroir trigger Oracle T2) : la durée est bornée à [1, 900 s].
 * Contrainte RG-F05 : volumeDonnees est NULL si statut ≠ "Réalisée" (affiché N/D).
 *
 * Codes couleur des badges de statut :
 *   Planifiée → bleu  (#2196F3)
 *   Réalisée  → vert  (#4CAF50)
 *   Annulée   → rouge (#F44336)
 */
@Composable
fun FenetreCard(
    fenetre: FenetreCom,
    nomStation: String,
    modifier: Modifier = Modifier
) {
    val (badgeColor, badgeLabel) = when (fenetre.statut) {
        "Réalisée"  -> Color(0xFF4CAF50) to "Réalisée"
        "Planifiée" -> Color(0xFF2196F3) to "Planifiée"
        else        -> Color(0xFFF44336) to "Annulée"
    }

    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {

            // En-tête : satellite → station + badge statut
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "${fenetre.idSatellite}  →  $nomStation",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Surface(
                    shape = RoundedCornerShape(50),
                    color = badgeColor
                ) {
                    Text(
                        text = badgeLabel,
                        style = MaterialTheme.typography.labelSmall,
                        color = Color.White,
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                    )
                }
            }

            // Date/heure de début
            Text(
                text = "Début : ${formatDatetime(fenetre)}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 4.dp)
            )

            // Durée + volume
            Row(modifier = Modifier.padding(top = 4.dp)) {
                Text(
                    text = "Durée : ${formatDuree(fenetre.duree)}",
                    style = MaterialTheme.typography.bodySmall
                )
                Spacer(modifier = Modifier.width(16.dp))
                Text(
                    text = "Vol. : ${fenetre.volumeDonnees?.let { "%.0f Mo".format(it) } ?: "N/D"}",
                    style = MaterialTheme.typography.bodySmall,
                    color = if (fenetre.volumeDonnees != null)
                        MaterialTheme.colorScheme.onSurface
                    else
                        MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Helpers privés
// ---------------------------------------------------------------------------

private fun formatDuree(dureeSecondes: Int): String {
    val min = dureeSecondes / 60
    val sec = dureeSecondes % 60
    return if (min > 0) "$min min %02d s".format(sec) else "$sec s"
}

private fun formatDatetime(fenetre: FenetreCom): String =
    SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.FRANCE).format(fenetre.datetimeDebut)

// ---------------------------------------------------------------------------
// Previews
// ---------------------------------------------------------------------------

@Preview(showBackground = true, name = "Fenêtre Réalisée")
@Composable
private fun PreviewRealisee() {
    MyApplicationTheme {
        FenetreCard(
            fenetre = mockFenetres[0],
            nomStation = mockStations[1].nomStation
        )
    }
}

@Preview(showBackground = true, name = "Fenêtre Planifiée (sans volume)")
@Composable
private fun PreviewPlanifiee() {
    MyApplicationTheme {
        FenetreCard(
            fenetre = mockFenetres[3],
            nomStation = mockStations[1].nomStation
        )
    }
}
