import can
import time
import struct
import math

# ==========================================
# CONFIGURATION
# ==========================================
# We simulate the ECU on 'can1'. Your Flutter app listens on 'can0'.
# Ensure physical wiring or vcan bridge exists.
try:
    # FIX: 'bustype' is deprecated, used 'interface' instead
    bus = can.Bus(channel='can1', interface='socketcan')
    print("🚀 RAPS ECU Simulator Started on can1...")
    print("   - Broadcasting: Angles, Currents, Solenoids (10Hz)")
    print("   - Listening: UDS Requests (Voltage/Calibration)")
except Exception as e:
    print(f"❌ Error initializing CAN: {e}")
    exit()

# ==========================================
# CONVERSION HELPERS
# ==========================================
def to_raw_angle(deg):
    """
    Source [1]: Resolution 1/256 deg/bit, Offset 125 deg
    Formula: Raw = (Angle + 125) * 256
    """
    val = int((deg + 125.0) * 256.0)
    return max(0, min(65535, val))

def to_raw_current(ma):
    """
    Source [1]: Resolution 1mA/bit, Offset 32000
    Formula: Raw = mA + 32000
    """
    val = int(ma + 32000)
    return max(0, min(65535, val))

# ==========================================
# MAIN LOOP
# ==========================================
def run_simulator():
    t = 0.0

    while True:
        # 1. SIMULATE PHYSICS (Sine Wave)
        # Axle 1 swings +/- 20 degrees
        sim_a1 = 20.0 * math.sin(t)

        # Rear Axles follow Ratio [Source 10]
        # Approx: A5 is 40% of A1, A6 is 60% of A1 (Opposite direction logic if applicable)
        sim_a5 = sim_a1 * 0.4
        sim_a6 = sim_a1 * 0.6

        # Simulate Currents (fluctuate with angle)
        sim_cur5 = 500 + abs(int(sim_a5 * 10)) # Base 500mA
        sim_cur6 = 500 + abs(int(sim_a6 * 10))

        # --- A. Axle Angles (ID: 0x18FF0108) ---
        # Source [1]: A1(0-15), A5(16-31), A6(32-47)
        msg_angles = can.Message(
            arbitration_id=0x18FF0108,
            data=struct.pack('<HHH',
                to_raw_angle(sim_a1),
                to_raw_angle(sim_a5),
                to_raw_angle(sim_a6)
            ) + b'\x00\x00', # Padding for last 2 bytes
            is_extended_id=True
        )
        bus.send(msg_angles)

        # --- B. Errors & Currents (ID: 0x18FF0208) ---
        # Source [1]: ErrA5(0-1), ErrA6(2-3), CurA5(4-5), CurA6(6-7)
        msg_metrics = can.Message(
            arbitration_id=0x18FF0208,
            data=struct.pack('<HHHH',
                to_raw_angle(0.0),    # No Error
                to_raw_angle(0.0),    # No Error
                to_raw_current(sim_cur5),
                to_raw_current(sim_cur6)
            ),
            is_extended_id=True
        )
        bus.send(msg_metrics)

        # --- C. Solenoid Status (ID: 0x18FF0308) ---
        # Source [1] Layout:
        # Byte 0: [LS(0-1) | A5L1(2-3) | A5L2(4-5) | A6L1(6-7)]
        # Byte 1: [A6L2(0-1) ...]
        # Status: 01 = ON (Green)

        # All ON (01) -> Binary 01010101 = 0x55
        byte0 = 0x55
        # A6Lk2 ON (01) -> Binary 00000001 = 0x01
        byte1 = 0x01

        msg_solenoids = can.Message(
            arbitration_id=0x18FF0308,
            data=bytearray([byte0, byte1, 0, 0, 0, 0, 0, 0]),
            is_extended_id=True
        )
        bus.send(msg_solenoids)

        # --- D. UDS SERVER RESPONDER (Updated for TATA 12x12 DIDs) ---
        msg = bus.recv(timeout=0.01)
        if msg and msg.arbitration_id == 0x1BDA08F1:
            service = msg.data[1]
            did = (msg.data[2] << 8) | msg.data[3]

            if service == 0x22: # READ
                if did == 0x220F: # Voltage
                    print("🔵 UDS Request: Voltage. Replying 24.5V...")
                    resp = [0x04, 0x62, 0x22, 0x0F, 0x00, 0xF5, 0x00, 0x00] # 24.5V
                elif did == 0x2210: # Axle 1 Angle
                    print("🔵 UDS Request: Axle 1 Angle. Replying 10.0°...")
                    resp = [0x04, 0x62, 0x22, 0x10, 0x00, 0x64, 0x00, 0x00] # 10.0°
                bus.send(can.Message(arbitration_id=0x1BDAF108, data=resp, is_extended_id=True))

            elif service == 0x2E: # WRITE / CALIBRATE
                print(f"🔴 TATA 12x12 Calibration Command Received for DID: {hex(did)}")
                resp = [0x03, 0x6E, msg.data[2], msg.data[3], 0, 0, 0, 0]
                bus.send(can.Message(arbitration_id=0x1BDAF108, data=resp, is_extended_id=True))

        # Timing
        time.sleep(0.1)
        t += 0.1

if __name__ == "__main__":
    try:
        run_simulator()
    except KeyboardInterrupt:
        print("\nStopping Simulator...")