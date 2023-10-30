// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

error NFTDropMarketNode_Address_Is_Not_A_Contract();

/**
 * @title Stores a reference to Foundation's NFTDropMarket contract for other mixins to leverage.
 * @author HardlyDifficult
 */
abstract contract NFTDropMarketNode {
  using AddressUpgradeable for address;

  address internal immutable nftDropMarket;

  constructor(address _nftDropMarket) {
    if (!_nftDropMarket.isContract()) {
      revert NFTDropMarketNode_Address_Is_Not_A_Contract();
    }

    nftDropMarket = _nftDropMarket;
  }

  /**
   * @notice Returns the address of the NFTDropMarket contract.
   */
  function getNftDropMarketAddress() external view returns (address market) {
    market = nftDropMarket;
  }

  // This mixin uses 0 slots.
}