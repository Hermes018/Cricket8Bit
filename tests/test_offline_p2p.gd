extends SceneTree
## Headless test: exercises OfflineMultiplayerMock discovery, connection, and packet transfer.
## Run with: godot --headless -s tests/test_offline_p2p.gd

func _init():
	print("=== Test: Offline P2P Mock ===")

	var host = OfflineMultiplayerMock.new()
	var client = OfflineMultiplayerMock.new()

	var found_peers: Array = []
	var host_connected: Array = []
	var client_connected: Array = []
	var received_packets: Array = []

	client.peer_found.connect(func(pid, name):
		found_peers.append({"id": pid, "name": name})
		print("  [client] Found peer: %s ('%s')" % [pid, name])
	)
	host.connected_to_peer.connect(func(pid):
		host_connected.append(pid)
		print("  [host] Connected to: %s" % pid)
	)
	client.connected_to_peer.connect(func(pid):
		client_connected.append(pid)
		print("  [client] Connected to: %s" % pid)
	)
	host.packet_received.connect(func(pid, data):
		received_packets.append({"from": pid, "data": data})
		print("  [host] Received packet from %s: %d bytes" % [pid, data.size()])
	)

	# Step 1: Host starts advertising
	var err = host.start_advertising("TestRoom")
	assert(err == OK, "Advertising should succeed")

	# Step 2: Client starts discovery — should find the host
	err = client.start_discovery()
	assert(err == OK, "Discovery should succeed")
	assert(found_peers.size() == 1, "Should have found 1 peer")
	assert(found_peers[0]["name"] == "TestRoom", "Peer name should be 'TestRoom'")

	# Step 3: Client connects to host
	var host_id = found_peers[0]["id"]
	err = client.connect_to_endpoint(host_id)
	assert(err == OK, "Connection should succeed")
	assert(host_connected.size() == 1, "Host should see 1 connection")
	assert(client_connected.size() == 1, "Client should see 1 connection")

	# Step 4: Client sends a delivery params packet to host
	var delivery_params = {
		"pace": 0.85,
		"pitch_x": 0.5,
		"pitch_length": 0.5,
		"swing": 0.1,
		"spin": -0.05,
	}
	var payload = var_to_bytes(delivery_params)
	err = client.send_packet(host_id, payload)
	assert(err == OK, "Send should succeed")
	assert(received_packets.size() == 1, "Host should have received 1 packet")

	# Decode and verify
	var decoded = bytes_to_var(received_packets[0]["data"])
	assert(decoded is Dictionary, "Decoded data should be Dictionary")
	assert(decoded["pace"] == 0.85, "Pace should match")
	print("  [decoded] pace=%.2f pitch_x=%.2f" % [decoded["pace"], decoded["pitch_x"]])

	# Step 5: Cleanup
	host.stop()
	client.stop()
	assert(not host.is_connected_to_any(), "Host should have no connections after stop")
	assert(not client.is_connected_to_any(), "Client should have no connections after stop")

	print("=== All tests PASSED ===")
	quit(0)
