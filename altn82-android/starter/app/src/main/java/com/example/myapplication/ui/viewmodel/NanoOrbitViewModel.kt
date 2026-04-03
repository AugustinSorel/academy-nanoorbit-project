package com.example.myapplication.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.myapplication.data.model.Satellite
import com.example.myapplication.data.model.StatutSatellite
import com.example.myapplication.data.model.mockSatellites
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

/**
 * ViewModel du Dashboard — Phase 1 (données simulées).
 * Phase 2 : injecter NanoOrbitRepository via Koin et remplacer loadSatellites().
 */
class NanoOrbitViewModel : ViewModel() {

    // Source de données (Phase 1 : mock — Phase 2 : repository injecté par Koin)
    private val _allSatellites = MutableStateFlow<List<Satellite>>(emptyList())

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    /**
     * Liste filtrée en temps réel selon la recherche.
     * Le filtrage est calculé ici (pas dans le composable) pour garantir la testabilité.
     * Critères : nom du satellite OU identifiant d'orbite.
     */
    val filteredSatellites: StateFlow<List<Satellite>> = combine(
        _allSatellites,
        _searchQuery
    ) { satellites, query ->
        if (query.isBlank()) {
            satellites
        } else {
            satellites.filter { sat ->
                sat.nomSatellite.contains(query, ignoreCase = true) ||
                    sat.idOrbite.contains(query, ignoreCase = true)
            }
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = emptyList()
    )

    /** Nombre de satellites opérationnels dans la liste filtrée courante. */
    val operationnelCount: StateFlow<Int> = filteredSatellites
        .combine(_allSatellites) { filtered, _ ->
            filtered.count { it.statut == StatutSatellite.OPERATIONNEL }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    init {
        loadSatellites()
    }

    fun loadSatellites() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            try {
                delay(600) // simulation latence réseau — Phase 2 : appel Retrofit réel
                _allSatellites.value = mockSatellites
            } catch (e: Exception) {
                _errorMessage.value = "Impossible de charger les satellites : ${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun onSearchQueryChange(query: String) {
        _searchQuery.value = query
    }

    fun dismissError() {
        _errorMessage.value = null
    }
}
