package com.example.myapplication.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Place
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.myapplication.ui.screen.DashboardScreen
import com.example.myapplication.ui.screen.DetailScreen
import com.example.myapplication.ui.screen.MapScreen
import com.example.myapplication.ui.screen.PlanningScreen

// ── Routes ──────────────────────────────────────────────────────────────────

object Routes {
    const val DASHBOARD = "dashboard"
    const val DETAIL    = "detail/{satelliteId}"
    const val PLANNING  = "planning"
    const val MAP       = "map"

    /** Construit l'URL de navigation vers le DetailScreen. */
    fun detail(satelliteId: String) = "detail/$satelliteId"
}

// ── Onglets du BottomNavigationBar ──────────────────────────────────────────

private data class BottomTab(
    val route: String,
    val label: String,
    val icon: ImageVector
)

private val bottomTabs = listOf(
    BottomTab(Routes.DASHBOARD, "Satellites", Icons.Default.Home),
    BottomTab(Routes.PLANNING,  "Planning",   Icons.Default.List),
    BottomTab(Routes.MAP,       "Carte",      Icons.Default.Place)
)

// ── NavHost principal ────────────────────────────────────────────────────────

/**
 * Point d'entrée de la navigation.
 *
 * Structure :
 *   - NavHost avec 4 routes (dashboard, detail/{id}, planning, map)
 *   - BottomNavigationBar visible sur Dashboard, Planning et Carte.
 *   - BottomNav masqué sur DetailScreen (consigne L3-A).
 *
 * Phase 3 — L3-A
 */
@Composable
fun AppNavHost() {
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

    // La BottomBar est masquée sur DetailScreen
    val showBottomBar = currentRoute != Routes.DETAIL &&
        !currentRoute.orEmpty().startsWith("detail/")

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                AppBottomBar(navController = navController, currentRoute = currentRoute)
            }
        }
    ) { innerPadding ->
        NavHost(
            navController    = navController,
            startDestination = Routes.DASHBOARD
        ) {
            // ── Dashboard ───────────────────────────────────────────────────
            composable(Routes.DASHBOARD) {
                DashboardScreen(
                    onSatelliteClick = { id -> navController.navigate(Routes.detail(id)) }
                )
            }

            // ── Detail (fiche satellite) ─────────────────────────────────────
            composable(
                route     = Routes.DETAIL,
                arguments = listOf(navArgument("satelliteId") { type = NavType.StringType })
            ) { backStack ->
                val satelliteId = backStack.arguments?.getString("satelliteId") ?: ""
                DetailScreen(
                    satelliteId = satelliteId,
                    onBack      = { navController.popBackStack() }
                )
            }

            // ── Planning ────────────────────────────────────────────────────
            composable(Routes.PLANNING) {
                PlanningScreen()
            }

            // ── Carte ────────────────────────────────────────────────────────
            composable(Routes.MAP) {
                MapScreen()
            }
        }
    }
}

// ── BottomNavigationBar ──────────────────────────────────────────────────────

@Composable
private fun AppBottomBar(navController: NavController, currentRoute: String?) {
    NavigationBar {
        bottomTabs.forEach { tab ->
            NavigationBarItem(
                selected = currentRoute == tab.route,
                onClick  = {
                    if (currentRoute != tab.route) {
                        navController.navigate(tab.route) {
                            // Évite l'empilement de destinations identiques
                            popUpTo(Routes.DASHBOARD) { saveState = true }
                            launchSingleTop = true
                            restoreState    = true
                        }
                    }
                },
                icon  = { Icon(tab.icon, contentDescription = tab.label) },
                label = { Text(tab.label) }
            )
        }
    }
}
