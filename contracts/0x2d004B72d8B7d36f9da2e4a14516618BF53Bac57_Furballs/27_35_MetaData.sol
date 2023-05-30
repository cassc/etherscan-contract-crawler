// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./FurLib.sol";

/// @title MetaData
/// @author LFG Gaming LLC
/// @notice Utilities for creating MetaData (e.g., OpenSea)
library MetaData {
  function trait(string memory traitType, string memory value) internal pure returns (bytes memory) {
    return abi.encodePacked('{"trait_type": "', traitType,'", "value": "', value, '"}, ');
  }

  function traitNumberDisplay(
    string memory traitType, string memory displayType, uint256 value
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(
      '{"trait_type": "', traitType,
      bytes(displayType).length > 0 ? '", "display_type": "' : '', displayType,
      '", "value": ', FurLib.uint2str(value), '}, '
    );
  }

  function traitValue(string memory traitType, uint256 value) internal pure returns (bytes memory) {
    return traitNumberDisplay(traitType, "", value);
  }

  /// @notice Convert a modifier percentage (120%) into a metadata +20% boost
  function traitBoost(
    string memory traitType, uint256 percent
  ) internal pure returns (bytes memory) {
    return traitNumberDisplay(traitType, "boost_percentage", percent > 100 ? (percent - 100) : 0);
  }

  function traitNumber(
    string memory traitType, uint256 value
  ) internal pure returns (bytes memory) {
    return traitNumberDisplay(traitType, "number", value);
  }

  function traitDate(
    string memory traitType, uint256 value
  ) internal pure returns (bytes memory) {
    return traitNumberDisplay(traitType, "date", value);
  }
}