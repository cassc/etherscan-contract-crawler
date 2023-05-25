// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/BinaryDecoder.sol';
import '../utils/PackedVarArray.sol';


library RightwayDecoder {
  struct DropContentLibrary {
    uint256 arweaveHash;
  }

  /*
   * content types:
   * 0 - image
   * 1 - vector
   * 2 - video
   * 3 - audio
   */
  struct DropContent {
    uint8  contentLibrary;
    uint8  contentType;
    uint16 contentIndex;
  }

  // encoded as uint16 keyref, uint8 array (0/1), uint16 value-ref
  // arrays will have multiple entries
  struct DropAttribute {
    uint16   key;        // from drop.stringData
    bool     isArray;
    uint16   value;     // from drop.stringData
  }

  struct DropTemplate {
    uint16   name;             // from drop.sentences joined with ' '
    uint16   description;      // from drop.sentences joined with ' '
    uint8    redemptions;
    uint64   redemptionExpiration;

    uint16   attributesStart;   // from drop.attributes
    uint16   attributesLength;  // from drop.attributes
    uint16   contentStart;      // from drop.content
    uint16   contentLength;     // from drop.content
  }

  struct DropEdition {
    uint16   template;
    uint16   size;
    uint16   attributesStart;  // from drop.attributes
    uint16   attributesLength; // from drop.attributes
    uint16   contentStart;     // from drop.content
    uint16   contentLength;    // from drop.content
  }

  struct DropToken {
    uint16   edition;
    uint16   serial;
  }

  struct Drop {
    DropContentLibrary[] contentLibraries; // max of 256 content libraries
    bytes32[0xFFFF] content;
    bytes32[0xFFFF] stringData; // max of 64k strings
    bytes32[0xFFFF] sentences;  // max of 64k strings
    bytes32[0xFFFF] attributes;
    bytes32[0xFFFF] templates;
    bytes32[0xFFFF] editions;
    bytes32[0xFFFF] tokens;
    uint numTokens;
  }

  function getBufferIndexAndOffset(uint index, uint stride) internal pure returns (uint, uint) {
    uint offset = index * stride;
    return (offset / 32, offset % 32);
  }

  function decodeDropAttribute(Drop storage drop, uint16 idx) public view returns ( DropAttribute memory ) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 6);
    DropAttribute memory result;

    uint8 isArray = 0;
    (result.key, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.attributes, bufferIndex, offset);
    (result.value, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.attributes, bufferIndex, offset);
    (isArray,,) = BinaryDecoder.decodeUint8(drop.attributes, bufferIndex, offset);
    result.isArray = isArray != 0;

    return result;
  }

  function decodeDropString(Drop storage drop, uint16 idx) public view returns ( string memory ) {
    return PackedVarArray.getString(drop.stringData, idx);
  }

  function copyBytesUsafe( bytes memory from, bytes memory to, uint offset) internal pure returns (uint){
    for (uint idx = 0; idx < from.length; idx++) {
      to[offset + idx] = from[idx];
    }
    return offset + from.length;
  }

  function decodeDropSentence(Drop storage drop, uint16 index ) public view returns (string memory) {
    uint16[] memory words = PackedVarArray.getUint16Array(drop.sentences, index);
    uint strLen = words.length - 1; // initialized to the number of spaces

    string[] memory strings = new string[](words.length);
    for (uint idx = 0; idx < words.length; idx++) {
      strings[idx] = PackedVarArray.getString(drop.stringData, words[idx]);
      strLen += bytes(strings[idx]).length;
    }

    bytes memory strRaw = new bytes(strLen);
    uint offset = 0;
    for (uint idx = 0; idx < words.length - 1; idx++) {
      offset = copyBytesUsafe(bytes(strings[idx]), strRaw, offset);
      strRaw[offset++] = 0x20; // ascii/utf8 space
    }

    copyBytesUsafe(bytes(strings[words.length - 1]), strRaw, offset);

    return string(strRaw);
  }

  function decodeDropEdition(Drop storage drop, uint16 idx) public view returns(DropEdition memory) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 12);
    DropEdition memory result;

    (result.template, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.editions, bufferIndex, offset);
    (result.size, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.editions, bufferIndex, offset);
    (result.attributesStart, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.editions, bufferIndex, offset);
    (result.attributesLength, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.editions, bufferIndex, offset);
    (result.contentStart, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.editions, bufferIndex, offset);
    (result.contentLength, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.editions, bufferIndex, offset);

    return result;
  }

  function decodeDropTemplate(Drop storage drop, uint16 idx) public view returns(DropTemplate memory) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 32);
    DropTemplate memory result;

    (result.name, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.templates, bufferIndex, offset);
    (result.description, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.templates, bufferIndex, offset);
    (result.redemptions, bufferIndex, offset) = BinaryDecoder.decodeUint8(drop.templates, bufferIndex, offset);
    (result.redemptionExpiration, bufferIndex, offset) = BinaryDecoder.decodeUint64Aligned(drop.templates, bufferIndex, offset);
    (result.attributesStart, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.templates, bufferIndex, offset);
    (result.attributesLength, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.templates, bufferIndex, offset);
    (result.contentStart, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.templates, bufferIndex, offset);
    (result.contentLength, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.templates, bufferIndex, offset);

    return result;
  }

  function decodeDropToken(Drop storage drop, uint16 idx) public view returns(DropToken memory) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 4);
    DropToken memory result;

    (result.edition, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.tokens, bufferIndex, offset);
    (result.serial, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.tokens, bufferIndex, offset);

    return result;
  }

  function decodeDropContent(Drop storage drop, uint16 idx) public view returns(DropContent memory) {
    DropContent memory result;
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 4);
    (result.contentLibrary, bufferIndex, offset) = BinaryDecoder.decodeUint8(drop.content, bufferIndex, offset);
    (result.contentType, bufferIndex, offset) = BinaryDecoder.decodeUint8(drop.content, bufferIndex, offset);
    (result.contentIndex, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.content, bufferIndex, offset);
    return result;
  }

  function getDropContentLibrary(Drop storage drop, uint16 idx) public view returns(DropContentLibrary storage) {
    return drop.contentLibraries[idx];
  }
}