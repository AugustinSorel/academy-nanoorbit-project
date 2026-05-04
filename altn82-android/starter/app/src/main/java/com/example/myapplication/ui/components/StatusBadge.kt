package com.example.myapplication.ui.components

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.myapplication.data.model.StatutSatellite
import com.example.myapplication.ui.theme.MyApplicationTheme

@Composable
fun StatusBadge(
    statut: StatutSatellite,
    modifier: Modifier = Modifier
) {
    val backgroundColor = when (statut) {
        StatutSatellite.OPERATIONNEL -> Color(0xFF4CAF50)
        StatutSatellite.EN_VEILLE    -> Color(0xFFFF9800)
        StatutSatellite.DEFAILLANT   -> Color(0xFFF44336)
        StatutSatellite.DESORBITE    -> Color(0xFF9E9E9E)
    }

    Surface(
        shape = RoundedCornerShape(50),
        color = backgroundColor,
        modifier = modifier
    ) {
        Text(
            text = statut.displayName,
            style = MaterialTheme.typography.labelSmall,
            color = Color.White,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
        )
    }
}

@Preview(showBackground = true, name = "Badge Opérationnel")
@Composable
private fun PreviewOperationnel() {
    MyApplicationTheme { StatusBadge(StatutSatellite.OPERATIONNEL) }
}

@Preview(showBackground = true, name = "Badge En veille")
@Composable
private fun PreviewEnVeille() {
    MyApplicationTheme { StatusBadge(StatutSatellite.EN_VEILLE) }
}

@Preview(showBackground = true, name = "Badge Défaillant")
@Composable
private fun PreviewDefaillant() {
    MyApplicationTheme { StatusBadge(StatutSatellite.DEFAILLANT) }
}

@Preview(showBackground = true, name = "Badge Désorbité")
@Composable
private fun PreviewDesorbite() {
    MyApplicationTheme { StatusBadge(StatutSatellite.DESORBITE) }
}
