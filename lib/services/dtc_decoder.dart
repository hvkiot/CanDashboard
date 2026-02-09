class DtcDecoder {
  // Source [9] - DTC Error Code Listing (Stored Faults)
  static String getDtcDescription(String hexCode) {
    const codes = {
      '0x5A0A00': 'Axle 5 Not Turning',
      '0x5A0B00': 'Axle 6 Not Turning',
      '0x5A0000': 'Axle 1 Sensor Missing',
      '0x5A0300': 'Axle 5 Valve Error',
      '0x5A0400': 'Axle 6 Valve Error',
      '0x5A0900': 'LS Valve Error',
      '0xC02888': 'CAN Bus Fault',
      '0x5A102F': 'Vehicle Speed Signal Lost',
    };
    return codes[hexCode] ?? "Unknown Fault: $hexCode";
  }

  // NEW: UDS Negative Response Code (NRC) Decoder
  // Used for real-time command rejections
  static String getNrcDescription(int code) {
    switch (code) {
      case 0x11:
        return "Service Not Supported";
      case 0x13:
        return "Incorrect Message Length";
      case 0x22:
        return "Conditions Not Correct (Check Speed/Gear)"; // Source [55]
      case 0x24:
        return "Request Sequence Error";
      case 0x31:
        return "Request Out of Range (Invalid Calibration Value)";
      case 0x33:
        return "Security Access Denied (Unlock ECU first)";
      case 0x7E:
        return "Sub-function Not Supported in Active Session";
      default:
        return "ECU Error: 0x${code.toRadixString(16).toUpperCase()}";
    }
  }
}
