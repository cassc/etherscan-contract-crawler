// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SecurityLib.sol";
import "./HashLib.sol";

library RoyaltyLib {
  struct RoyaltyData {
    address recipient;
    uint256 bps;
  }

  uint256 private constant _BPS_BASE = 10000;

  bytes32 private constant _ROYALTY_TYPEHASH = keccak256(bytes("RoyaltyData(address recipient,uint256 bps)"));

  function hashStruct(RoyaltyData memory royaltyData) internal pure returns (bytes32) {
    return keccak256(abi.encode(_ROYALTY_TYPEHASH, royaltyData.recipient, royaltyData.bps));
  }

  function validate(RoyaltyData memory royaltyData) internal pure returns (bool, string memory) {
    if (royaltyData.recipient == address(0x0)) {
      return (false, "RoyaltyLib: recipient verification failed");
    }

    if (royaltyData.bps == 0 || royaltyData.bps > _BPS_BASE) {
      return (false, "RoyaltyLib: bps verification failed");
    }

    return (true, "");
  }

  function calc(uint256 salePrice, uint256 bps) internal pure returns (uint256) {
    return (salePrice * bps) / _BPS_BASE;
  }

  function isNotNull(RoyaltyLib.RoyaltyData memory royaltyData) internal pure returns (bool) {
    return (royaltyData.recipient != address(0x0) && royaltyData.bps != 0);
  }
}