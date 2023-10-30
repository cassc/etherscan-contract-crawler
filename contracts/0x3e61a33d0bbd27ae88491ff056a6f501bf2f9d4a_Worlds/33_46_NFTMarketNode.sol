// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

error NFTMarketNode_Address_Is_Not_A_Contract();

/**
 * @title Stores a reference to Foundation's NFTMarket contract for other mixins to leverage.
 * @author HardlyDifficult
 */
abstract contract NFTMarketNode {
  using AddressUpgradeable for address;

  address internal immutable nftMarket;

  constructor(address _nftMarket) {
    if (!_nftMarket.isContract()) {
      revert NFTMarketNode_Address_Is_Not_A_Contract();
    }

    nftMarket = _nftMarket;
  }

  /**
   * @notice Returns the address of the NFTMarket contract.
   */
  function getNftMarketAddress() external view returns (address market) {
    market = nftMarket;
  }

  // This mixin uses 0 slots.
}