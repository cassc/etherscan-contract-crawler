// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @title FurLib
/// @author LFG Gaming LLC
/// @notice Utilities for Furballs
/// @dev Each of the structs are designed to fit within 256
library FurLib {
  // Metadata about a wallet.
  struct Account {
    uint64 created;       // First time this account received a furball
    uint32 numFurballs;   // Number of furballs it currently holds
    uint32 maxFurballs;   // Max it has ever held
    uint16 maxLevel;      // Max level of any furball it currently holds
    uint16 reputation;    // Value assigned by moderators to boost standing
    uint16 standing;      // Computed current standing
    uint8 permissions;    // 0 = user, 1 = moderator, 2 = admin, 3 = owner
  }

  // Key data structure given to clients for high-level furball access (furballs.stats)
  struct FurballStats {
    uint16 expRate;
    uint16 furRate;
    RewardModifiers modifiers;
    Furball definition;
    Snack[] snacks;
  }

  // The response from a single play session indicating rewards
  struct Rewards {
    uint16 levels;
    uint32 experience;
    uint32 fur;
    uint128 loot;
  }

  // Stored data structure in Furballs master contract which keeps track of mutable data
  struct Furball {
    uint32 number;        // Overall number, starting with 1
    uint16 count;         // Index within the collection
    uint16 rarity;        // Total rarity score for later boosts
    uint32 experience;    // EXP
    uint32 zone;          // When exploring, the zone number. Otherwise, battling.
    uint16 level;         // Current EXP => level; can change based on level up during collect
    uint16 weight;        // Total weight (number of items in inventory)
    uint64 birth;         // Timestamp of furball creation
    uint64 trade;         // Timestamp of last furball trading wallets
    uint64 last;          // Timestamp of last action (battle/explore)
    uint32 moves;         // The size of the collection array for this furball, which is move num.
    uint256[] inventory;  // IDs of items in inventory
  }

  // A runtime-calculated set of properties that can affect Furball production during collect()
  struct RewardModifiers {
    uint16 expPercent;
    uint16 furPercent;
    uint16 luckPercent;
    uint16 happinessPoints;
    uint16 energyPoints;
    uint32 zone;
  }

  // For sale via loot engine.
  struct Snack {
    uint32 snackId;       // Unique ID
    uint32 duration;      // How long it lasts, !expressed in intervals!
    uint16 furCost;       // How much FUR
    uint16 happiness;     // +happiness bost points
    uint16 energy;        // +energy boost points
    uint16 count;         // How many in stack?
    uint64 fed;           // When was it fed (if it is active)?
  }

  // Input to the feed() function for multi-play
  struct Feeding {
    uint256 tokenId;
    uint32 snackId;
    uint16 count;
  }

  uint32 public constant Max32 = type(uint32).max;

  uint8 public constant PERMISSION_USER = 1;
  uint8 public constant PERMISSION_MODERATOR = 2;
  uint8 public constant PERMISSION_ADMIN = 4;
  uint8 public constant PERMISSION_OWNER = 5;
  uint8 public constant PERMISSION_CONTRACT = 0x10;

  uint32 public constant EXP_PER_INTERVAL = 500;
  uint32 public constant FUR_PER_INTERVAL = 100;

  uint8 public constant LOOT_BYTE_STAT = 1;
  uint8 public constant LOOT_BYTE_RARITY = 2;

  uint8 public constant SNACK_BYTE_ENERGY = 0;
  uint8 public constant SNACK_BYTE_HAPPINESS = 2;

  uint256 public constant OnePercent = 1000;
  uint256 public constant OneHundredPercent = 100000;

  /// @notice Shortcut for equations that saves gas
  /// @dev The expression (0x100 ** byteNum) is expensive; this covers byte packing for editions.
  function bytePower(uint8 byteNum) internal pure returns (uint256) {
    if (byteNum == 0) return 0x1;
    if (byteNum == 1) return 0x100;
    if (byteNum == 2) return 0x10000;
    if (byteNum == 3) return 0x1000000;
    if (byteNum == 4) return 0x100000000;
    if (byteNum == 5) return 0x10000000000;
    if (byteNum == 6) return 0x1000000000000;
    if (byteNum == 7) return 0x100000000000000;
    if (byteNum == 8) return 0x10000000000000000;
    if (byteNum == 9) return 0x1000000000000000000;
    if (byteNum == 10) return 0x100000000000000000000;
    if (byteNum == 11) return 0x10000000000000000000000;
    if (byteNum == 12) return 0x1000000000000000000000000;
    return (0x100 ** byteNum);
  }

  /// @notice Helper to get a number of bytes from a value
  function extractBytes(uint value, uint8 startAt, uint8 numBytes) internal pure returns (uint) {
    return (value / bytePower(startAt)) % bytePower(numBytes);
  }

  /// @notice Converts exp into a sqrt-able number.
  function expToLevel(uint32 exp, uint32 maxExp) internal pure returns(uint256) {
    exp = exp > maxExp ? maxExp : exp;
    return sqrt(exp < 100 ? 0 : ((exp + exp - 100) / 100));
  }

  /// @notice Simple square root function using the Babylonian method
  function sqrt(uint32 x) internal pure returns(uint256) {
    if (x < 1) return 0;
    if (x < 4) return 1;
    uint z = (x + 1) / 2;
    uint y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
    return y;
  }

  /// @notice Convert bytes into a hex str, e.g., an address str
  function bytesHex(bytes memory data) internal pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(data.length * 2);
    for (uint i = 0; i < data.length; i++) {
        str[i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[1 + i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
      k = k-1;
      uint8 temp = (48 + uint8(_i - _i / 10 * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

    string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    uint256 encodedLen = 4 * ((data.length + 2) / 3);
    string memory result = new string(encodedLen + 32);

    assembly {
      mstore(result, encodedLen)
      let tablePtr := add(table, 1)

      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))
      let resultPtr := add(result, 32)

      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)
        let input := mload(dataPtr)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(input, 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
      }

      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}