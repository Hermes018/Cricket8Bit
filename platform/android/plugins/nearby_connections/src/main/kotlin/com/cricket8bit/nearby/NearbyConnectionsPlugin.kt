package com.cricket8bit.nearby

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.*
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

/**
 * Godot 4 Android Plugin wrapping Google Nearby Connections API.
 *
 * Strategy: P2P_STAR (one advertiser / host, multiple discoverers / challengers).
 * Transport: Nearby Connections automatically selects BLE, Wi-Fi Direct, or Wi-Fi LAN —
 *            all of which work in airplane mode with local radios enabled.
 *
 * Signals emitted to GDScript:
 *   - peer_found(peer_id: String, endpoint_name: String)
 *   - peer_lost(peer_id: String)
 *   - connected_to_peer(peer_id: String)
 *   - disconnected_from_peer(peer_id: String)
 *   - packet_received(peer_id: String, data: ByteArray)
 *   - permission_result(granted: Boolean)
 */
class NearbyConnectionsPlugin(godot: Godot) : GodotPlugin(godot) {

    companion object {
        private const val TAG = "NearbyConnPlugin"
        private const val SERVICE_ID = "com.cricket8bit.nearby"
        private const val PERM_REQUEST_CODE = 9001

        private val REQUIRED_PERMISSIONS = arrayOf(
            Manifest.permission.BLUETOOTH_ADVERTISE,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.ACCESS_FINE_LOCATION,
        )
    }

    override fun getPluginName(): String = "NearbyConnections"

    override fun getPluginSignals(): MutableSet<SignalInfo> = mutableSetOf(
        SignalInfo("peer_found", String::class.java, String::class.java),
        SignalInfo("peer_lost", String::class.java),
        SignalInfo("connected_to_peer", String::class.java),
        SignalInfo("disconnected_from_peer", String::class.java),
        SignalInfo("packet_received", String::class.java, ByteArray::class.java),
        SignalInfo("permission_result", Boolean::class.java),
    )

    private val strategy = Strategy.P2P_STAR

    private lateinit var connectionsClient: ConnectionsClient

    override fun onMainCreate(pActivity: Activity): android.view.View? {
        connectionsClient = Nearby.getConnectionsClient(pActivity)
        return super.onMainCreate(pActivity)
    }

    // --- Permission handling ---

    @UsedByGodot
    fun requestPermissions() {
        val activity = activity ?: return
        val missing = REQUIRED_PERMISSIONS.filter {
            ContextCompat.checkSelfPermission(activity, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            emitSignal("permission_result", true)
        } else {
            ActivityCompat.requestPermissions(activity, missing.toTypedArray(), PERM_REQUEST_CODE)
        }
    }

    override fun onMainRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>?, grantResults: IntArray?
    ) {
        if (requestCode == PERM_REQUEST_CODE) {
            val allGranted = grantResults?.all { it == PackageManager.PERMISSION_GRANTED } ?: false
            emitSignal("permission_result", allGranted)
        }
    }

    // --- Advertising (Host) ---

    private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, info: ConnectionInfo) {
            Log.d(TAG, "Connection initiated from: $endpointId (${info.endpointName})")
            // Auto-accept for simplicity; a production app would show a confirmation dialog.
            connectionsClient.acceptConnection(endpointId, payloadCallback)
        }

        override fun onConnectionResult(endpointId: String, result: ConnectionResolution) {
            if (result.status.isSuccess) {
                Log.d(TAG, "Connected to: $endpointId")
                emitSignal("connected_to_peer", endpointId)
            } else {
                Log.w(TAG, "Connection failed to: $endpointId (${result.status})")
            }
        }

        override fun onDisconnected(endpointId: String) {
            Log.d(TAG, "Disconnected from: $endpointId")
            emitSignal("disconnected_from_peer", endpointId)
        }
    }

    @UsedByGodot
    fun startAdvertising(roomName: String) {
        val options = AdvertisingOptions.Builder().setStrategy(strategy).build()
        connectionsClient.startAdvertising(roomName, SERVICE_ID, connectionLifecycleCallback, options)
            .addOnSuccessListener { Log.d(TAG, "Advertising started as '$roomName'") }
            .addOnFailureListener { e -> Log.e(TAG, "Advertising failed", e) }
    }

    @UsedByGodot
    fun stopAdvertising() {
        connectionsClient.stopAdvertising()
    }

    // --- Discovery (Challenger) ---

    private val endpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            Log.d(TAG, "Endpoint found: $endpointId (${info.endpointName})")
            emitSignal("peer_found", endpointId, info.endpointName)
        }

        override fun onEndpointLost(endpointId: String) {
            Log.d(TAG, "Endpoint lost: $endpointId")
            emitSignal("peer_lost", endpointId)
        }
    }

    @UsedByGodot
    fun startDiscovery() {
        val options = DiscoveryOptions.Builder().setStrategy(strategy).build()
        connectionsClient.startDiscovery(SERVICE_ID, endpointDiscoveryCallback, options)
            .addOnSuccessListener { Log.d(TAG, "Discovery started") }
            .addOnFailureListener { e -> Log.e(TAG, "Discovery failed", e) }
    }

    @UsedByGodot
    fun stopDiscovery() {
        connectionsClient.stopDiscovery()
    }

    // --- Connection request ---

    @UsedByGodot
    fun connectToEndpoint(endpointId: String) {
        connectionsClient.requestConnection("Cricket8Bit", endpointId, connectionLifecycleCallback)
            .addOnSuccessListener { Log.d(TAG, "Connection requested to $endpointId") }
            .addOnFailureListener { e -> Log.e(TAG, "Connection request failed", e) }
    }

    // --- Payload (data transfer) ---

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            if (payload.type == Payload.Type.BYTES) {
                val bytes = payload.asBytes() ?: return
                emitSignal("packet_received", endpointId, bytes)
            }
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
            // Could track progress for large payloads; not needed for game state packets.
        }
    }

    @UsedByGodot
    fun sendPacket(peerId: String, data: ByteArray) {
        connectionsClient.sendPayload(peerId, Payload.fromBytes(data))
    }

    // --- Cleanup ---

    @UsedByGodot
    fun stopAll() {
        connectionsClient.stopAllEndpoints()
        connectionsClient.stopAdvertising()
        connectionsClient.stopDiscovery()
    }

    override fun onMainDestroy() {
        stopAll()
        super.onMainDestroy()
    }
}
