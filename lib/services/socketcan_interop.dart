import 'dart:ffi';

// Load the standard Linux C library
final DynamicLibrary libc = DynamicLibrary.open('libc.so.6');

// --- C Function Signatures ---
typedef SocketFunc = Int32 Function(Int32 domain, Int32 type, Int32 protocol);
typedef Socket = int Function(int domain, int type, int protocol);

typedef BindFunc =
    Int32 Function(Int32 sockfd, Pointer<SockAddrCan> addr, Int32 addrlen);
typedef Bind = int Function(int sockfd, Pointer<SockAddrCan> addr, int addrlen);

typedef ReadFunc = Int32 Function(Int32 fd, Pointer<CanFrame> buf, Int32 count);
typedef Read = int Function(int fd, Pointer<CanFrame> buf, int count);

typedef WriteFunc =
    Int32 Function(Int32 fd, Pointer<CanFrame> buf, Int32 count);
typedef Write = int Function(int fd, Pointer<CanFrame> buf, int count);

typedef IoctlFunc = Int32 Function(Int32 fd, Int32 request, Pointer<IfReq> ifr);
typedef Ioctl = int Function(int fd, int request, Pointer<IfReq> ifr);

typedef CloseFunc = Int32 Function(Int32 fd);
typedef Close = int Function(int fd);

// --- Bind C Functions to Dart ---
final socket = libc.lookupFunction<SocketFunc, Socket>('socket');
final bind = libc.lookupFunction<BindFunc, Bind>('bind');
final read = libc.lookupFunction<ReadFunc, Read>('read');
final write = libc.lookupFunction<WriteFunc, Write>('write');
final ioctl = libc.lookupFunction<IoctlFunc, Ioctl>('ioctl');
final close = libc.lookupFunction<CloseFunc, Close>('close');

// --- C Structs mapped to Dart ---

base class SockAddrCan extends Struct {
  @Int16()
  external int canFamily;
  @Int32()
  external int canIfIndex;
  @Int32()
  external int canAddrTpRxId;
  @Int32()
  external int canAddrTpTxId;
}

base class CanFrame extends Struct {
  @Uint32()
  external int canId; // 32 bit: CAN_ID + EFF/RTR/ERR flags
  @Uint8()
  external int canDlc; // Data length code (0-8)
  @Uint8()
  external int pad;
  @Uint8()
  external int res0;
  @Uint8()
  external int res1;
  @Array(8)
  external Array<Uint8> data;
}

base class IfReq extends Struct {
  @Array(16)
  external Array<Uint8> ifrName;
  @Int32()
  external int ifrIfIndex;
}

// --- Constants for Linux SocketCAN ---
const int pfCan = 29; // Protocol Family CAN
const int sockRaw = 3; // Raw socket
const int canRaw = 1; // Raw CAN protocol
const int siocGifIndex = 0x8933; // Get Interface Index IOCTL

// --- Bitmasks for CAN IDs ---
const int canIdMask = 0x1FFFFFFF; // 29-bit Extended ID Mask
const int canEffFlag = 0x80000000; // Extended Frame Format Flag
const int canErrFlag = 0x20000000; // Error Frame Flag

// --- Error Frame Content Masks ---
const int canErrBusOff = 0x00000040;
const int canErrCrtl = 0x00000004;
