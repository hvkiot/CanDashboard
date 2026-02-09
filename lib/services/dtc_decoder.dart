class DtcDecoder {
  // Source [9] - DTC Error Code Listing
  static String getDescription(String hexCode) {
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
}
