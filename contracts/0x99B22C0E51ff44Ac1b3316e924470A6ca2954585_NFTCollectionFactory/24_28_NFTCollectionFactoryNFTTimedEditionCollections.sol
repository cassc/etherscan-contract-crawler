// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";

import "../../../libraries/AddressLibrary.sol";
import "../../../libraries/TimeLibrary.sol";

import "../../../interfaces/internal/routes/INFTCollectionFactoryTimedEditions.sol";

import "../NFTCollectionFactorySharedTemplates.sol";

/**
 * @title A factory to create NFTTimedEditionCollection contracts.
 */
abstract contract NFTCollectionFactoryNFTTimedEditionCollections is
  INFTCollectionFactoryTimedEditions,
  Context,
  NFTCollectionFactorySharedTemplates
{
  using TimeLibrary for uint256;

  struct NFTTimedEditionCollectionCreationConfig {
    string name;
    string symbol;
    string tokenURI;
    uint256 mintEndTime;
    address approvedMinter;
    address payable paymentAddress;
    uint96 nonce;
  }

  /**
   * @notice Emitted when a new NFTTimedEditionCollection is created from this factory.
   * @param collection The address of the new NFT drop collection contract.
   * @param creator The address of the creator which owns the new collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param tokenURI The token URI for the collection.
   * @param mintEndTime The time at which minting will end.
   * @param paymentAddress The address that will receive royalties and mint payments.
   * @param version The implementation version used by the new NFTTimedEditionCollection collection.
   * @param nonce The nonce used by the creator to create this collection.
   */
  event NFTTimedEditionCollectionCreated(
    address indexed collection,
    address indexed creator,
    address indexed approvedMinter,
    string name,
    string symbol,
    string tokenURI,
    uint256 mintEndTime,
    address paymentAddress,
    uint256 version,
    uint256 nonce
  );

  /**
   * @notice Create a new drop collection contract.
   * @dev The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param tokenURI The base URI for the collection.
   * @param mintEndTime The time at which minting will end.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTTimedEditionCollection(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce
  ) external returns (address collection) {
    collection = _createNFTTimedEditionCollection(
      NFTTimedEditionCollectionCreationConfig(name, symbol, tokenURI, mintEndTime, approvedMinter, payable(0), nonce)
    );
  }

  /**
   * @notice Create a new drop collection contract with a custom payment address.
   * @dev All params other than `paymentAddress` are the same as in `createNFTTimedEditionCollection`.
   * The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param tokenURI The base URI for the collection.
   * @param mintEndTime The time at which minting will end.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @param paymentAddress The address that will receive royalties and mint payments.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTTimedEditionCollectionWithPaymentAddress(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce,
    address payable paymentAddress
  ) external returns (address collection) {
    collection = _createNFTTimedEditionCollection(
      NFTTimedEditionCollectionCreationConfig(
        name,
        symbol,
        tokenURI,
        mintEndTime,
        approvedMinter,
        paymentAddress != _msgSender() ? paymentAddress : payable(0),
        nonce
      )
    );
  }

  /**
   * @notice Create a new drop collection contract with a custom payment address derived from the factory.
   * @dev All params other than `paymentAddressFactoryCall` are the same as in `createNFTTimedEditionCollection`.
   * The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param tokenURI The base URI for the collection.
   * @param mintEndTime The time at which minting will end.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @param paymentAddressFactoryCall The contract call which will return the address to use for payments.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTTimedEditionCollectionWithPaymentFactory(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce,
    CallWithoutValue calldata paymentAddressFactoryCall
  ) external returns (address collection) {
    collection = _createNFTTimedEditionCollection(
      NFTTimedEditionCollectionCreationConfig(
        name,
        symbol,
        tokenURI,
        mintEndTime,
        approvedMinter,
        AddressLibrary.callAndReturnContractAddress(paymentAddressFactoryCall),
        nonce
      )
    );
  }

  function _createNFTTimedEditionCollection(
    NFTTimedEditionCollectionCreationConfig memory creationConfig
  ) private returns (address collection) {
    address payable sender = payable(_msgSender());
    uint256 version;
    (collection, version) = _createCollection(
      CollectionType.NFTTimedEditionCollection,
      sender,
      creationConfig.nonce,
      creationConfig.symbol
    );

    emit NFTTimedEditionCollectionCreated(
      collection,
      sender,
      creationConfig.approvedMinter,
      creationConfig.name,
      creationConfig.symbol,
      creationConfig.tokenURI,
      creationConfig.mintEndTime,
      creationConfig.paymentAddress,
      version,
      creationConfig.nonce
    );

    INFTTimedEditionCollectionInitializer(collection).initialize(
      sender,
      creationConfig.name,
      creationConfig.symbol,
      creationConfig.tokenURI,
      creationConfig.mintEndTime,
      creationConfig.approvedMinter,
      creationConfig.paymentAddress
    );
  }

  // This mixin consumes 0 slots.
}