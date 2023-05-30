// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./FurLib.sol";

/// @title FurLib
/// @author LFG Gaming LLC
/// @notice Public utility library around game-specific equations and constants
library FurDefs {
  function rarityName(uint8 rarity) internal pure returns(string memory) {
    if (rarity == 0) return "Common";
    if (rarity == 1) return "Elite";
    if (rarity == 2) return "Mythic";
    if (rarity == 3) return "Legendary";
    return "Ultimate";
  }

  function raritySuffix(uint8 rarity) internal pure returns(string memory) {
    return rarity == 0 ? "" : string(abi.encodePacked(" (", rarityName(rarity), ")"));
  }

  function renderPoints(uint64 ptr, bytes memory data) internal pure returns (uint64, bytes memory) {
    uint8 cnt = uint8(data[ptr]);
    ptr++;
    bytes memory points = "";
    for (uint256 i=0; i<cnt; i++) {
      uint16 x = uint8(data[ptr]) * 256 + uint8(data[ptr + 1]);
      uint16 y = uint8(data[ptr + 2]) * 256 + uint8(data[ptr + 3]);
      points = abi.encodePacked(points, FurLib.uint2str(x), ',', FurLib.uint2str(y), i == (cnt - 1) ? '': ' ');
      ptr += 4;
    }
    return (ptr, abi.encodePacked('points="', points, '" '));
  }

  function renderTransform(uint64 ptr, bytes memory data) internal pure returns (uint64, bytes memory) {
    uint8 len = uint8(data[ptr]);
    ptr++;
    bytes memory points = "";
    for (uint256 i=0; i<len; i++) {
      bytes memory point = "";
      (ptr, point) =  unpackFloat(ptr, data);
      points = i == (len - 1) ? abi.encodePacked(points, point) : abi.encodePacked(points, point, ' ');
    }
    return (ptr, abi.encodePacked('transform="matrix(', points, ')" '));
  }

  function renderDisplay(uint64 ptr, bytes memory data) internal pure returns (uint64, bytes memory) {
    string[2] memory vals = ['inline', 'none'];
    return (ptr + 1, abi.encodePacked('display="', vals[uint8(data[ptr])], '" '));
  }

  function renderFloat(uint64 ptr, bytes memory data) internal pure returns (uint64, bytes memory) {
    uint8 propType = uint8(data[ptr]);
    string[2] memory floatMap = ['opacity', 'offset'];
    bytes memory floatVal = "";
    (ptr, floatVal) =  unpackFloat(ptr + 1, data);
    return (ptr, abi.encodePacked(floatMap[propType], '="', floatVal,'" '));
  }

  function  unpackFloat(uint64 ptr, bytes memory data) internal pure returns(uint64, bytes memory) {
    uint8 decimals = uint8(data[ptr]);
    ptr++;
    if (decimals == 0) return (ptr, '0');
    uint8 hi = decimals / 16;
    uint16 wholeNum = 0;
    decimals = decimals % 16;
    if (hi >= 10) {
      wholeNum = uint16(uint8(data[ptr]) * 256 + uint8(data[ptr + 1]));
      ptr += 2;
    } else if (hi >= 8) {
      wholeNum = uint16(uint8(data[ptr]));
      ptr++;
    }
    if (decimals == 0) return (ptr, abi.encodePacked(hi % 2 == 1 ? '-' : '', FurLib.uint2str(wholeNum)));

    bytes memory remainder = new bytes(decimals);
    for (uint8 d=0; d<decimals; d+=2) {
      remainder[d] = bytes1(48 + uint8(data[ptr] >> 4));
      if ((d + 1) < decimals) {
        remainder[d+1] = bytes1(48 + uint8(data[ptr] & 0x0f));
      }
      ptr++;
    }
    return (ptr, abi.encodePacked(hi % 2 == 1 ? '-' : '', FurLib.uint2str(wholeNum), '.', remainder));
  }

  function renderInt(uint64 ptr, bytes memory data) internal pure returns (uint64, bytes memory) {
    uint8 propType = uint8(data[ptr]);
    string[13] memory intMap = ['cx', 'cy', 'x', 'x1', 'x2', 'y', 'y1', 'y2', 'r', 'rx', 'ry', 'width', 'height'];
    uint16 val = uint16(uint8(data[ptr + 1]) * 256) + uint8(data[ptr + 2]);
    if (val >= 0x8000) {
      return (ptr + 3, abi.encodePacked(intMap[propType], '="-', FurLib.uint2str(uint32(0x10000 - val)),'" '));
    }
    return (ptr + 3, abi.encodePacked(intMap[propType], '="', FurLib.uint2str(val),'" '));
  }

  function renderStr(uint64 ptr, bytes memory data) internal pure returns(uint64, bytes memory) {
    string[4] memory strMap = ['id', 'enable-background', 'gradientUnits', 'gradientTransform'];
    uint8 t = uint8(data[ptr]);
    require(t < 4, 'STR');
    bytes memory str = "";
    (ptr, str) =  unpackStr(ptr + 1, data);
    return (ptr, abi.encodePacked(strMap[t], '="', str, '" '));
  }

  function unpackStr(uint64 ptr, bytes memory data) internal pure returns(uint64, bytes memory) {
    uint8 len = uint8(data[ptr]);
    bytes memory str = bytes(new string(len));
    for (uint8 i=0; i<len; i++) {
      str[i] = data[ptr + 1 + i];
    }
    return (ptr + 1 + len, str);
  }
}