// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

import "../../../libraries/AddressLibrary.sol";

/**
 * @title Interface for routing calls to the NFT Collection Factory to create timed edition collections.
 * @author HardlyDifficult
 */
interface INFTCollectionFactoryTimedEditions {
  function createNFTTimedEditionCollection(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce
  ) external returns (address collection);

  function createNFTTimedEditionCollectionWithPaymentFactory(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce,
    CallWithoutValue calldata paymentAddressFactoryCall
  ) external returns (address collection);
}