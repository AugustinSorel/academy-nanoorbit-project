package com.example.myapplication.ui.screen

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Paint
import android.graphics.drawable.ShapeDrawable
import android.graphics.drawable.shapes.OvalShape
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.example.myapplication.data.model.StationSol
import com.example.myapplication.ui.viewmodel.NanoOrbitViewModel
import org.koin.androidx.compose.koinViewModel
import org.osmdroid.config.Configuration
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MapScreen(
    vm: NanoOrbitViewModel = koinViewModel()
) {
    val context = LocalContext.current
    val stations by vm.stations.collectAsState()
    var mapView by remember { mutableStateOf<MapView?>(null) }
    var hasLocationPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(
                context, Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        )
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        hasLocationPermission = permissions[Manifest.permission.ACCESS_FINE_LOCATION] == true ||
            permissions[Manifest.permission.ACCESS_COARSE_LOCATION] == true
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "Stations sol",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = {
                if (hasLocationPermission) {
                    centerOnUserLocation(mapView)
                } else {
                    permissionLauncher.launch(
                        arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                        )
                    )
                }
            }) {
                Icon(Icons.Default.LocationOn, contentDescription = "Me localiser")
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            AndroidView(
                modifier = Modifier.fillMaxSize(),
                factory = { ctx ->
                    Configuration.getInstance().userAgentValue = ctx.packageName

                    MapView(ctx).also { mv ->
                        mapView = mv
                        mv.setTileSource(TileSourceFactory.MAPNIK)
                        mv.setMultiTouchControls(true)
                        mv.controller.setZoom(3.0)
                        mv.controller.setCenter(GeoPoint(20.0, 10.0))
                    }
                },
                update = { mv ->
                    mv.overlays.clear()
                    addStationMarkers(mv, stations)
                }
            )
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            mapView?.onDetach()
        }
    }
}

private fun addStationMarkers(mapView: MapView, stations: List<StationSol>) {
    stations.forEach { station ->
        val marker = Marker(mapView)
        marker.position = GeoPoint(station.latitude, station.longitude)
        marker.title   = station.nomStation
        marker.snippet = "Bande : ${station.bandeFrequence} | Débit max : ${station.debitMax} Mbps"

        val color = when (station.statut) {
            "Active"      -> Color.parseColor("#4CAF50")
            "Maintenance" -> Color.parseColor("#FF9800")
            else          -> Color.parseColor("#9E9E9E")
        }
        marker.icon = createCircleDrawable(color)
        marker.setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_CENTER)

        mapView.overlays.add(marker)
    }
    mapView.invalidate()
}

private fun createCircleDrawable(color: Int): android.graphics.drawable.Drawable {
    val shape = ShapeDrawable(OvalShape())
    shape.intrinsicWidth  = 40
    shape.intrinsicHeight = 40
    shape.paint.color = color
    shape.paint.style = Paint.Style.FILL
    return shape
}

private fun centerOnUserLocation(mapView: MapView?) {
    mapView ?: return
    try {
        val lm = mapView.context.getSystemService(android.content.Context.LOCATION_SERVICE)
            as android.location.LocationManager
        @Suppress("MissingPermission")
        val location = lm.getLastKnownLocation(android.location.LocationManager.GPS_PROVIDER)
            ?: lm.getLastKnownLocation(android.location.LocationManager.NETWORK_PROVIDER)
        location?.let {
            mapView.controller.animateTo(GeoPoint(it.latitude, it.longitude))
            mapView.controller.setZoom(10.0)
        }
    } catch (_: Exception) {
    }
}
