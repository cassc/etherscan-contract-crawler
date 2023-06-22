// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "../VbtcToken.sol";

/// @title  VBTC Token.
/// @notice This is the VBTC ERC20 contract.
contract MockVbtcUpgraded is VbtcToken {
  // TODO: implement
  // bytes calldata _header,
  // bytes calldata _proof,
  // uint256 _index,
  // bytes32 _txid,
  function proofP2FSHAndMint(
    bytes calldata _header,
    bytes calldata _proof,
    uint256 _index,
    bytes32 _txid
  ) external override returns (bool) {
    return true;
  }
}