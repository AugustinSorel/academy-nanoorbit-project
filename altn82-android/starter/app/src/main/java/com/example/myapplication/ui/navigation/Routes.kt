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

object Routes {
    const val DASHBOARD = "dashboard"
    const val DETAIL    = "detail/{satelliteId}"
    const val PLANNING  = "planning"
    const val MAP       = "map"

    fun detail(satelliteId: String) = "detail/$satelliteId"
}

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

@Composable
fun AppNavHost() {
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

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
            composable(Routes.DASHBOARD) {
                DashboardScreen(
                    onSatelliteClick = { id -> navController.navigate(Routes.detail(id)) }
                )
            }

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

            composable(Routes.PLANNING) {
                PlanningScreen()
            }

            composable(Routes.MAP) {
                MapScreen()
            }
        }
    }
}

@Composable
private fun AppBottomBar(navController: NavController, currentRoute: String?) {
    NavigationBar {
        bottomTabs.forEach { tab ->
            NavigationBarItem(
                selected = currentRoute == tab.route,
                onClick  = {
                    if (currentRoute != tab.route) {
                        navController.navigate(tab.route) {
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
