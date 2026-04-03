package com.example.myapplication.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
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
import com.example.myapplication.data.model.Instrument
import com.example.myapplication.data.model.mockInstruments
import com.example.myapplication.ui.theme.MyApplicationTheme

/**
 * Ligne d'instrument embarqué affichée dans la fiche détail d'un satellite.
 *
 * Paramètres :
 *   instrument           → données du catalogue INSTRUMENT (Oracle)
 *   etatFonctionnement   → état de l'association EMBARQUEMENT pour ce couple (sat, instr)
 *                          Valeurs : Actif | Nominal | Dégradé | Inactif | Hors service
 *
 * La résolution est affichée "N/A" si null (cas du récepteur AIS — RG-I01).
 *
 * Codes couleur de l'état de fonctionnement (miroir CHECK EMBARQUEMENT.etat_fonctionnement) :
 *   Actif / Nominal   → vert   (#4CAF50)
 *   Dégradé           → orange (#FF9800)
 *   Inactif / Hors service → gris (#9E9E9E)
 */
@Composable
fun InstrumentItem(
    instrument: Instrument,
    etatFonctionnement: String,
    modifier: Modifier = Modifier,
    showDivider: Boolean = true
) {
    val etatColor = when (etatFonctionnement) {
        "Actif", "Nominal"        -> Color(0xFF4CAF50)
        "Dégradé"                 -> Color(0xFFFF9800)
        "Inactif", "Hors service" -> Color(0xFF9E9E9E)
        else                      -> Color(0xFF9E9E9E)
    }

    val resolutionText = instrument.resolution?.let { "%.1f m".format(it) } ?: "N/A"

    Column(modifier = modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                // Type et modèle
                Text(
                    text = instrument.typeInstrument,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Row(modifier = Modifier.padding(top = 2.dp)) {
                    Text(
                        text = instrument.modele,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "Résol. : $resolutionText",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Text(
                    text = instrument.refInstrument,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.outline,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }

            Spacer(modifier = Modifier.width(8.dp))

            // Indicateur d'état de fonctionnement
            Surface(
                shape = RoundedCornerShape(50),
                color = etatColor
            ) {
                Text(
                    text = etatFonctionnement,
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.White,
                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                )
            }
        }

        if (showDivider) {
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
        }
    }
}

// ---------------------------------------------------------------------------
// Previews
// ---------------------------------------------------------------------------

@Preview(showBackground = true, name = "Instrument Actif (avec résolution)")
@Composable
private fun PreviewActif() {
    MyApplicationTheme {
        InstrumentItem(
            instrument = mockInstruments[0],    // Caméra optique
            etatFonctionnement = "Actif",
            showDivider = false
        )
    }
}

@Preview(showBackground = true, name = "Instrument AIS (résolution N/A)")
@Composable
private fun PreviewAis() {
    MyApplicationTheme {
        InstrumentItem(
            instrument = mockInstruments[2],    // Récepteur AIS — resolution = null
            etatFonctionnement = "Actif",
            showDivider = false
        )
    }
}

@Preview(showBackground = true, name = "Instrument Dégradé")
@Composable
private fun PreviewDegrade() {
    MyApplicationTheme {
        InstrumentItem(
            instrument = mockInstruments[1],    // Infrarouge
            etatFonctionnement = "Dégradé",
            showDivider = false
        )
    }
}

@Preview(showBackground = true, name = "Instrument Inactif")
@Composable
private fun PreviewInactif() {
    MyApplicationTheme {
        InstrumentItem(
            instrument = mockInstruments[3],    // Spectromètre
            etatFonctionnement = "Inactif",
            showDivider = false
        )
    }
}
