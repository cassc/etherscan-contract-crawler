// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";

import "../NFTCollectionFactorySharedTemplates.sol";

/**
 * @title A factory to create NFTCollection contracts.
 */
abstract contract NFTCollectionFactoryNFTCollections is Context, NFTCollectionFactorySharedTemplates {
  /**
   * @notice Emitted when a new NFTCollection is created from this factory.
   * @param collection The address of the new NFT collection contract.
   * @param creator The address of the creator which owns the new collection.
   * @param version The implementation version used by the new collection.
   * @param name The name of the collection contract created.
   * @param symbol The symbol of the collection contract created.
   * @param nonce The nonce used by the creator when creating the collection,
   * used to define the address of the collection.
   */
  event NFTCollectionCreated(
    address indexed collection,
    address indexed creator,
    uint256 indexed version,
    string name,
    string symbol,
    uint256 nonce
  );

  /**
   * @notice Create a new collection contract.
   * @dev The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTCollection(
    string calldata name,
    string calldata symbol,
    uint96 nonce
  ) external returns (address collection) {
    uint256 version;
    address payable sender = payable(_msgSender());
    (collection, version) = _createCollection(CollectionType.NFTCollection, sender, nonce, symbol);
    emit NFTCollectionCreated(collection, sender, version, name, symbol, nonce);

    INFTCollectionInitializer(collection).initialize(sender, name, symbol);
  }

  // This mixin consumes 0 slots.
}