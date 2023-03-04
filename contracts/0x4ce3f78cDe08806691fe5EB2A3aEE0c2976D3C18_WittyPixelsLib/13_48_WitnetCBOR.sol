// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./WitnetBuffer.sol";

/// @title A minimalistic implementation of “RFC 7049 Concise Binary Object Representation”
/// @notice This library leverages a buffer-like structure for step-by-step decoding of bytes so as to minimize
/// the gas cost of decoding them into a useful native type.
/// @dev Most of the logic has been borrowed from Patrick Gansterer’s cbor.js library: https://github.com/paroga/cbor-js
/// @author The Witnet Foundation.
/// 
/// TODO: add support for Map (majorType = 5)
/// TODO: add support for Float32 (majorType = 7, additionalInformation = 26)
/// TODO: add support for Float64 (majorType = 7, additionalInformation = 27) 

library WitnetCBOR {

  using WitnetBuffer for WitnetBuffer.Buffer;
  using WitnetCBOR for WitnetCBOR.CBOR;

  /// Data struct following the RFC-7049 standard: Concise Binary Object Representation.
  struct CBOR {
      WitnetBuffer.Buffer buffer;
      uint8 initialByte;
      uint8 majorType;
      uint8 additionalInformation;
      uint64 len;
      uint64 tag;
  }

  uint8 internal constant MAJOR_TYPE_INT = 0;
  uint8 internal constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 internal constant MAJOR_TYPE_BYTES = 2;
  uint8 internal constant MAJOR_TYPE_STRING = 3;
  uint8 internal constant MAJOR_TYPE_ARRAY = 4;
  uint8 internal constant MAJOR_TYPE_MAP = 5;
  uint8 internal constant MAJOR_TYPE_TAG = 6;
  uint8 internal constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint32 internal constant UINT32_MAX = type(uint32).max;
  uint64 internal constant UINT64_MAX = type(uint64).max;
  
  error EmptyArray();
  error InvalidLengthEncoding(uint length);
  error UnexpectedMajorType(uint read, uint expected);
  error UnsupportedPrimitive(uint primitive);
  error UnsupportedMajorType(uint unexpected);  

  modifier isMajorType(
      WitnetCBOR.CBOR memory cbor,
      uint8 expected
  ) {
    if (cbor.majorType != expected) {
      revert UnexpectedMajorType(cbor.majorType, expected);
    }
    _;
  }

  modifier notEmpty(WitnetBuffer.Buffer memory buffer) {
    if (buffer.data.length == 0) {
      revert WitnetBuffer.EmptyBuffer();
    }
    _;
  }

  function eof(CBOR memory cbor)
    internal pure
    returns (bool)
  {
    return cbor.buffer.cursor >= cbor.buffer.data.length;
  }

  /// @notice Decode a CBOR structure from raw bytes.
  /// @dev This is the main factory for CBOR instances, which can be later decoded into native EVM types.
  /// @param bytecode Raw bytes representing a CBOR-encoded value.
  /// @return A `CBOR` instance containing a partially decoded value.
  function fromBytes(bytes memory bytecode)
    internal pure
    returns (CBOR memory)
  {
    WitnetBuffer.Buffer memory buffer = WitnetBuffer.Buffer(bytecode, 0);
    return fromBuffer(buffer);
  }

  /// @notice Decode a CBOR structure from raw bytes.
  /// @dev This is an alternate factory for CBOR instances, which can be later decoded into native EVM types.
  /// @param buffer A Buffer structure representing a CBOR-encoded value.
  /// @return A `CBOR` instance containing a partially decoded value.
  function fromBuffer(WitnetBuffer.Buffer memory buffer)
    internal pure
    notEmpty(buffer)
    returns (CBOR memory)
  {
    uint8 initialByte;
    uint8 majorType = 255;
    uint8 additionalInformation;
    uint64 tag = UINT64_MAX;
    uint256 len;
    bool isTagged = true;
    while (isTagged) {
      // Extract basic CBOR properties from input bytes
      initialByte = buffer.readUint8();
      len ++;
      majorType = initialByte >> 5;
      additionalInformation = initialByte & 0x1f;
      // Early CBOR tag parsing.
      if (majorType == MAJOR_TYPE_TAG) {
        uint _cursor = buffer.cursor;
        tag = readLength(buffer, additionalInformation);
        len += buffer.cursor - _cursor;
      } else {
        isTagged = false;
      }
    }
    if (majorType > MAJOR_TYPE_CONTENT_FREE) {
      revert UnsupportedMajorType(majorType);
    }
    return CBOR(
      buffer,
      initialByte,
      majorType,
      additionalInformation,
      uint64(len),
      tag
    );
  }

  function fork(WitnetCBOR.CBOR memory self)
    internal pure
    returns (WitnetCBOR.CBOR memory)
  {
    return CBOR({
      buffer: self.buffer.fork(),
      initialByte: self.initialByte,
      majorType: self.majorType,
      additionalInformation: self.additionalInformation,
      len: self.len,
      tag: self.tag
    });
  }

  function settle(CBOR memory self)
      internal pure
      returns (WitnetCBOR.CBOR memory)
  {
    if (!self.eof()) {
      return fromBuffer(self.buffer);
    } else {
      return self;
    }
  }

  function skip(CBOR memory self)
      internal pure
      returns (WitnetCBOR.CBOR memory)
  {
    if (
      self.majorType == MAJOR_TYPE_INT
        || self.majorType == MAJOR_TYPE_NEGATIVE_INT
    ) {
      self.buffer.cursor += self.peekLength();
    } else if (
        self.majorType == MAJOR_TYPE_STRING
          || self.majorType == MAJOR_TYPE_BYTES
    ) {
      uint64 len = readLength(self.buffer, self.additionalInformation);
      self.buffer.cursor += len;
    } else if (
      self.majorType == MAJOR_TYPE_ARRAY
    ) { 
      self.len = readLength(self.buffer, self.additionalInformation);      
    // } else if (
    //   self.majorType == MAJOR_TYPE_CONTENT_FREE
    // ) {
      // TODO
    } else {
      revert UnsupportedMajorType(self.majorType);
    }
    return self;
  }

  function peekLength(CBOR memory self)
    internal pure
    returns (uint64)
  {
    assert(1 << 0 == 1);
    if (self.additionalInformation < 24) {
      return self.additionalInformation;
    } else if (self.additionalInformation > 27) {
      revert InvalidLengthEncoding(self.additionalInformation);
    } else {
      return uint64(1 << (self.additionalInformation - 24));
    }
  }

  // event Array(uint cursor, uint items);
  // event Log2(uint index, bytes data, uint cursor, uint major, uint addinfo, uint len);
  function readArray(CBOR memory self)
    internal pure
    isMajorType(self, MAJOR_TYPE_ARRAY)
    returns (CBOR[] memory items)
  {
    uint64 len = readLength(self.buffer, self.additionalInformation);
    // emit Array(self.buffer.cursor, len);
    items = new CBOR[](len + 1);
    for (uint ix = 0; ix < len; ix ++) {
      items[ix] = self.fork().settle();
      // emit Log2(
      //   ix,
      //   items[ix].buffer.data,
      //   items[ix].buffer.cursor,
      //   items[ix].majorType,
      //   items[ix].additionalInformation,
      //   items[ix].len
      // );
      self.buffer.cursor = items[ix].buffer.cursor;
      self.majorType = items[ix].majorType;
      self.additionalInformation = items[ix].additionalInformation;
      self.len = items[ix].len;
      if (self.majorType == MAJOR_TYPE_ARRAY) {
        CBOR[] memory subitems = self.readArray();
        self = subitems[subitems.length - 1];
      } else {
        self.skip();
      }
    }
    items[len] = self;
  }

  /// Reads the length of the settle CBOR item from a buffer, consuming a different number of bytes depending on the
  /// value of the `additionalInformation` argument.
  function readLength(
      WitnetBuffer.Buffer memory buffer,
      uint8 additionalInformation
    ) 
    internal pure
    returns (uint64)
  {
    if (additionalInformation < 24) {
      return additionalInformation;
    }
    if (additionalInformation == 24) {
      return buffer.readUint8();
    }
    if (additionalInformation == 25) {
      return buffer.readUint16();
    }
    if (additionalInformation == 26) {
      return buffer.readUint32();
    }
    if (additionalInformation == 27) {
      return buffer.readUint64();
    }
    if (additionalInformation == 31) {
      return UINT64_MAX;
    }
    revert InvalidLengthEncoding(additionalInformation);
  }

  /// @notice Read a `CBOR` structure into a native `bool` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as a `bool` value.
  function readBool(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (bool)
  {
    if (cbor.additionalInformation == 20) {
      return false;
    } else if (cbor.additionalInformation == 21) {
      return true;
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `bytes` value.
  /// @param cbor An instance of `CBOR`.
  /// @return output The value represented by the input, as a `bytes` value.   
  function readBytes(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_BYTES)
    returns (bytes memory output)
  {
    cbor.len = readLength(
      cbor.buffer,
      cbor.additionalInformation
    );
    if (cbor.len == UINT32_MAX) {
      // These checks look repetitive but the equivalent loop would be more expensive.
      uint32 length = uint32(_readIndefiniteStringLength(
        cbor.buffer,
        cbor.majorType
      ));
      if (length < UINT32_MAX) {
        output = abi.encodePacked(cbor.buffer.read(length));
        length = uint32(_readIndefiniteStringLength(
          cbor.buffer,
          cbor.majorType
        ));
        if (length < UINT32_MAX) {
          output = abi.encodePacked(
            output,
            cbor.buffer.read(length)
          );
        }
      }
    } else {
      return cbor.buffer.read(uint32(cbor.len));
    }
  }

  /// @notice Decode a `CBOR` structure into a `fixed16` value.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`
  /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function readFloat16(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (int32)
  {
    if (cbor.additionalInformation == 25) {
      return cbor.buffer.readFloat16();
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int128[]` value whose inner values follow the same convention 
  /// @notice as explained in `decodeFixed16`.
  /// @param cbor An instance of `CBOR`.
  function readFloat16Array(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (int32[] memory values)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      values = new int32[](length);
      for (uint64 i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        values[i] = readFloat16(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int128` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function readInt(CBOR memory cbor)
    internal pure
    returns (int)
  {
    if (cbor.majorType == 1) {
      uint64 _value = readLength(
        cbor.buffer,
        cbor.additionalInformation
      );
      return int(-1) - int(uint(_value));
    } else if (cbor.majorType == 0) {
      // Any `uint64` can be safely casted to `int128`, so this method supports majorType 1 as well so as to have offer
      // a uniform API for positive and negative numbers
      return int(readUint(cbor));
    }
    else {
      revert UnexpectedMajorType(cbor.majorType, 1);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int[]` value.
  /// @param cbor instance of `CBOR`.
  /// @return array The value represented by the input, as an `int[]` value.
  function readIntArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (int[] memory array)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      array = new int[](length);
      for (uint i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        array[i] = readInt(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `string` value.
  /// @param cbor An instance of `CBOR`.
  /// @return text The value represented by the input, as a `string` value.
  function readString(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_STRING)
    returns (string memory text)
  {
    cbor.len = readLength(cbor.buffer, cbor.additionalInformation);
    if (cbor.len == UINT64_MAX) {
      bool _done;
      while (!_done) {
        uint64 length = _readIndefiniteStringLength(
          cbor.buffer,
          cbor.majorType
        );
        if (length < UINT64_MAX) {
          text = string(abi.encodePacked(
            text,
            cbor.buffer.readText(length / 4)
          ));
        } else {
          _done = true;
        }
      }
    } else {
      return string(cbor.buffer.readText(cbor.len));
    }
  }

  /// @notice Decode a `CBOR` structure into a native `string[]` value.
  /// @param cbor An instance of `CBOR`.
  /// @return strings The value represented by the input, as an `string[]` value.
  function readStringArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (string[] memory strings)
  {
    uint length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      strings = new string[](length);
      for (uint i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        strings[i] = readString(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `uint64` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `uint64` value.
  function readUint(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_INT)
    returns (uint)
  {
    return readLength(
      cbor.buffer,
      cbor.additionalInformation
    );
  }

  /// @notice Decode a `CBOR` structure into a native `uint64[]` value.
  /// @param cbor An instance of `CBOR`.
  /// @return values The value represented by the input, as an `uint64[]` value.
  function readUintArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (uint[] memory values)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      values = new uint[](length);
      for (uint ix = 0; ix < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        values[ix] = readUint(item);
        unchecked {
          ix ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }  

  /// Read the length of a CBOR indifinite-length item (arrays, maps, byte strings and text) from a buffer, consuming
  /// as many bytes as specified by the first byte.
  function _readIndefiniteStringLength(
      WitnetBuffer.Buffer memory buffer,
      uint8 majorType
    )
    private pure
    returns (uint64 len)
  {
    uint8 initialByte = buffer.readUint8();
    if (initialByte == 0xff) {
      return UINT64_MAX;
    }
    len = readLength(
      buffer,
      initialByte & 0x1f
    );
    if (len >= UINT64_MAX) {
      revert InvalidLengthEncoding(len);
    } else if (majorType != (initialByte >> 5)) {
      revert UnexpectedMajorType((initialByte >> 5), majorType);
    }
  }
 
}