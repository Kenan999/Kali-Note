package com.example.kalinote.connectivity

import android.content.Context
import android.util.Log
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.*
import com.google.android.gms.tasks.OnFailureListener
import com.google.android.gms.tasks.OnSuccessListener
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.nio.charset.StandardCharsets

class NearbyManager(private val context: Context) {
    private val TAG = "NearbyManager"
    private val SERVICE_ID = "com.example.kalinote.nearby"
    private val STRATEGY = Strategy.P2P_POINT_TO_POINT

    private val connectionsClient = Nearby.getConnectionsClient(context)
    private var opponentEndpointId: String? = null

    private val _isConnected = MutableStateFlow(false)
    val isConnected = _isConnected.asStateFlow()

    private val _receivedScanRequest = MutableStateFlow(false)
    val receivedScanRequest = _receivedScanRequest.asStateFlow()

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            if (payload.type == Payload.Type.BYTES) {
                val data = String(payload.asBytes()!!, StandardCharsets.UTF_8)
                if (data == "REQUEST_SCAN") {
                    _receivedScanRequest.value = true
                }
            }
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {}
    }

    private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, info: ConnectionInfo) {
            connectionsClient.acceptConnection(endpointId, payloadCallback)
        }

        override fun onConnectionResult(endpointId: String, result: ConnectionResolution) {
            if (result.status.isSuccess) {
                opponentEndpointId = endpointId
                _isConnected.value = true
                connectionsClient.stopAdvertising()
                connectionsClient.stopDiscovery()
            }
        }

        override fun onDisconnected(endpointId: String) {
            opponentEndpointId = null
            _isConnected.value = false
            startP2P()
        }
    }

    fun startP2P() {
        startAdvertising()
        startDiscovery()
    }

    fun requestRemoteScan() {
        opponentEndpointId?.let {
            val payload = Payload.fromBytes("REQUEST_SCAN".toByteArray(StandardCharsets.UTF_8))
            connectionsClient.sendPayload(it, payload)
        }
    }

    fun resetScanRequest() {
        _receivedScanRequest.value = false
    }

    private fun startAdvertising() {
        val options = AdvertisingOptions.Builder().setStrategy(STRATEGY).build()
        connectionsClient.startAdvertising(android.os.Build.MODEL, SERVICE_ID, connectionLifecycleCallback, options)
    }

    private fun startDiscovery() {
        val options = DiscoveryOptions.Builder().setStrategy(STRATEGY).build()
        connectionsClient.startDiscovery(SERVICE_ID, object : EndpointDiscoveryCallback() {
            override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
                connectionsClient.requestConnection(android.os.Build.MODEL, endpointId, connectionLifecycleCallback)
            }
            override fun onEndpointLost(endpointId: String) {}
        }, options)
    }
}
