// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";

import "../../../libraries/AddressLibrary.sol";

import "../NFTCollectionFactorySharedTemplates.sol";

/**
 * @title A factory to create NFTDropCollection contracts.
 */
abstract contract NFTCollectionFactoryNFTDropCollections is Context, NFTCollectionFactorySharedTemplates {
  struct NFTDropCollectionCreationConfig {
    string name;
    string symbol;
    string baseURI;
    bool isRevealed;
    uint32 maxTokenId;
    address approvedMinter;
    address payable paymentAddress;
    uint96 nonce;
  }

  /**
   * @notice Emitted when a new NFTDropCollection is created from this factory.
   * @param collection The address of the new NFT drop collection contract.
   * @param creator The address of the creator which owns the new collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param baseURI The base URI for the collection.
   * @param isRevealed Whether the collection is revealed or not.
   * @param maxTokenId The max `tokenID` for this collection.
   * @param paymentAddress The address that will receive royalties and mint payments.
   * @param version The implementation version used by the new NFTDropCollection collection.
   * @param nonce The nonce used by the creator to create this collection.
   */
  event NFTDropCollectionCreated(
    address indexed collection,
    address indexed creator,
    address indexed approvedMinter,
    string name,
    string symbol,
    string baseURI,
    bool isRevealed,
    uint256 maxTokenId,
    address paymentAddress,
    uint256 version,
    uint256 nonce
  );

  /**
   * @notice Create a new drop collection contract.
   * @dev The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param baseURI The base URI for the collection.
   * @param isRevealed Whether the collection is revealed or not.
   * @param maxTokenId The max token id for this collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTDropCollection(
    string calldata name,
    string calldata symbol,
    string calldata baseURI,
    bool isRevealed,
    uint32 maxTokenId,
    address approvedMinter,
    uint96 nonce
  ) external returns (address collection) {
    collection = _createNFTDropCollection(
      NFTDropCollectionCreationConfig(name, symbol, baseURI, isRevealed, maxTokenId, approvedMinter, payable(0), nonce)
    );
  }

  /**
   * @notice Create a new drop collection contract with a custom payment address.
   * @dev All params other than `paymentAddress` are the same as in `createNFTDropCollection`.
   * The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param baseURI The base URI for the collection.
   * @param isRevealed Whether the collection is revealed or not.
   * @param maxTokenId The max token id for this collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @param paymentAddress The address that will receive royalties and mint payments.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTDropCollectionWithPaymentAddress(
    string calldata name,
    string calldata symbol,
    string calldata baseURI,
    bool isRevealed,
    uint32 maxTokenId,
    address approvedMinter,
    uint96 nonce,
    address payable paymentAddress
  ) external returns (address collection) {
    collection = _createNFTDropCollection(
      NFTDropCollectionCreationConfig(
        name,
        symbol,
        baseURI,
        isRevealed,
        maxTokenId,
        approvedMinter,
        paymentAddress != _msgSender() ? paymentAddress : payable(0),
        nonce
      )
    );
  }

  /**
   * @notice Create a new drop collection contract with a custom payment address derived from the factory.
   * @dev All params other than `paymentAddressFactoryCall` are the same as in `createNFTDropCollection`.
   * The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param baseURI The base URI for the collection.
   * @param isRevealed Whether the collection is revealed or not.
   * @param maxTokenId The max token id for this collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @param paymentAddressFactoryCall The contract call which will return the address to use for payments.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTDropCollectionWithPaymentFactory(
    string calldata name,
    string calldata symbol,
    string calldata baseURI,
    bool isRevealed,
    uint32 maxTokenId,
    address approvedMinter,
    uint96 nonce,
    CallWithoutValue calldata paymentAddressFactoryCall
  ) external returns (address collection) {
    collection = _createNFTDropCollection(
      NFTDropCollectionCreationConfig(
        name,
        symbol,
        baseURI,
        isRevealed,
        maxTokenId,
        approvedMinter,
        AddressLibrary.callAndReturnContractAddress(paymentAddressFactoryCall),
        nonce
      )
    );
  }

  function _createNFTDropCollection(
    NFTDropCollectionCreationConfig memory creationConfig
  ) private returns (address collection) {
    address payable sender = payable(_msgSender());
    uint256 version;
    (collection, version) = _createCollection(
      CollectionType.NFTDropCollection,
      sender,
      creationConfig.nonce,
      creationConfig.symbol
    );

    emit NFTDropCollectionCreated(
      collection,
      sender,
      creationConfig.approvedMinter,
      creationConfig.name,
      creationConfig.symbol,
      creationConfig.baseURI,
      creationConfig.isRevealed,
      creationConfig.maxTokenId,
      creationConfig.paymentAddress,
      version,
      creationConfig.nonce
    );

    INFTDropCollectionInitializer(collection).initialize(
      sender,
      creationConfig.name,
      creationConfig.symbol,
      creationConfig.baseURI,
      creationConfig.isRevealed,
      creationConfig.maxTokenId,
      creationConfig.approvedMinter,
      creationConfig.paymentAddress
    );
  }

  // This mixin consumes 0 slots.
}