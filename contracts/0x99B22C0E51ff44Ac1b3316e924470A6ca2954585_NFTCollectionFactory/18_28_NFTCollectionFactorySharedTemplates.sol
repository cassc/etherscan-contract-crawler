// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./NFTCollectionFactoryACL.sol";
import "./NFTCollectionFactoryTemplateInitializer.sol";
import "./NFTCollectionFactoryTypes.sol";

error NFTCollectionFactorySharedTemplates_Collection_Requires_Symbol();
error NFTCollectionFactorySharedTemplates_Invalid_Collection_Type();
error NFTCollectionFactorySharedTemplates_Upgrade_Implementation_Already_Set();
error NFTCollectionFactorySharedTemplates_Upgrade_Implementation_Not_A_Contract();
error NFTCollectionFactorySharedTemplates_Upgrade_Inputs_Must_Be_The_Same_Length();

/**
 * @title Shared logic for managing templates and creating new collections.
 */
abstract contract NFTCollectionFactorySharedTemplates is
  Context,
  Initializable,
  NFTCollectionFactoryACL,
  NFTCollectionFactoryTemplateInitializer
{
  using AddressUpgradeable for address;
  using Clones for address;

  // Struct for storage
  struct CollectionTemplateDetails {
    address implementation;
    uint32 version;
    // This slot has 64-bits of free space remaining.
  }

  mapping(CollectionType => CollectionTemplateDetails) private collectionTypeToTemplateDetails;

  /**
   * @notice Emitted when the implementation of NFTCollection used by new collections is updated.
   * @param implementation The new implementation contract address.
   * @param version The version of the new implementation, auto-incremented.
   */
  event CollectionTemplateUpdated(
    CollectionType indexed collectionType,
    address indexed implementation,
    uint256 indexed version
  );

  /**
   * @notice Called at the time of deployment / upgrade to initialize the factory with existing templates.
   * @param nftCollectionImplementation The implementation contract address for NFTCollection.
   * @param nftDropCollectionImplementation The implementation contract address for NFTDropCollection.
   * @param nftTimedEditionCollectionImplementation The implementation contract address for NFTTimedEditionCollection.
   * @dev This can be used to ensure there is zero downtime during an upgrade and that version numbers resume from
   * where they had left off.
   * Initializer 1 was previously used on mainnet. 2 was used on Goerli only.
   */
  function initialize(
    address nftCollectionImplementation,
    address nftDropCollectionImplementation,
    address nftTimedEditionCollectionImplementation
  ) external reinitializer(3) {
    // The latest version on mainnet before this upgrade was 3, so we start with 4.
    _setCollectionTemplate(CollectionType.NFTCollection, nftCollectionImplementation, 4);
    // The latest version on mainnet before this upgrade was 1, so we start with 2.
    _setCollectionTemplate(CollectionType.NFTDropCollection, nftDropCollectionImplementation, 2);
    // Editions are a new template, starting at version 1.
    _setCollectionTemplate(CollectionType.NFTTimedEditionCollection, nftTimedEditionCollectionImplementation, 1);
  }

  /**
   * @notice Allows admins to update a multiple templates.
   * @param collectionTypes The types of collections to update.
   * @param implementations The new implementation contract addresses, one per collection type provided.
   * @dev New templates will start with version 1, others will auto-increment from their current version.
   */
  function adminUpdateCollectionTemplates(
    CollectionType[] calldata collectionTypes,
    address[] calldata implementations
  ) external onlyAdmin {
    if (collectionTypes.length != implementations.length) {
      revert NFTCollectionFactorySharedTemplates_Upgrade_Inputs_Must_Be_The_Same_Length();
    }
    for (uint i = 0; i < collectionTypes.length; ) {
      if (collectionTypeToTemplateDetails[collectionTypes[i]].implementation == implementations[i]) {
        revert NFTCollectionFactorySharedTemplates_Upgrade_Implementation_Already_Set();
      }

      _setCollectionTemplate(
        collectionTypes[i],
        implementations[i],
        ++collectionTypeToTemplateDetails[collectionTypes[i]].version
      );

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice A helper for creating collections of a given type.
   */
  function _createCollection(
    CollectionType collectionType,
    address creator,
    uint96 nonce,
    string memory symbol
  ) internal returns (address collection, uint256 version) {
    // All collections require a symbol.
    if (bytes(symbol).length == 0) {
      revert NFTCollectionFactorySharedTemplates_Collection_Requires_Symbol();
    }

    address implementation = collectionTypeToTemplateDetails[collectionType].implementation;
    if (implementation == address(0)) {
      // This will occur if the collectionType is NULL or has not yet been initialized.
      revert NFTCollectionFactorySharedTemplates_Invalid_Collection_Type();
    }

    // This reverts if the NFT was previously created using this implementation version + msg.sender + nonce
    collection = implementation.cloneDeterministic(_getSalt(creator, nonce));
    version = collectionTypeToTemplateDetails[collectionType].version;
  }

  function _setCollectionTemplate(CollectionType collectionType, address implementation, uint32 version) private {
    if (!implementation.isContract()) {
      revert NFTCollectionFactorySharedTemplates_Upgrade_Implementation_Not_A_Contract();
    }

    collectionTypeToTemplateDetails[collectionType] = CollectionTemplateDetails(implementation, version);

    // Initialize will revert if the collectionType is NULL
    _initializeTemplate(collectionType, implementation, version);

    emit CollectionTemplateUpdated(collectionType, implementation, version);
  }

  /**
   * @notice Gets the latest implementation and version to be used by new collections of the given type.
   * @param collectionType The type of collection to get the template details for.
   * @return implementation The address of the implementation contract.
   * @return version The version of the current template.
   */
  function getCollectionTemplateDetails(
    CollectionType collectionType
  ) external view returns (address implementation, uint version) {
    CollectionTemplateDetails memory templateDetails = collectionTypeToTemplateDetails[collectionType];
    implementation = templateDetails.implementation;
    version = templateDetails.version;
  }

  /**
   * @notice Returns the address of an NFTDropCollection collection given the current
   * implementation version, creator, and nonce.
   * @param collectionType The type of collection this creator has or will create.
   * @param creator The creator of the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the collection contract that would be created by this nonce.
   * @dev This will return the same address whether the collection has already been created or not.
   * Returns address(0) if the collection type is not supported.
   */
  function predictCollectionAddress(
    CollectionType collectionType,
    address creator,
    uint96 nonce
  ) public view returns (address collection) {
    address implementation = collectionTypeToTemplateDetails[collectionType].implementation;
    if (implementation == address(0)) {
      // This will occur if the collectionType is NULL or has not yet been initialized.
      revert NFTCollectionFactorySharedTemplates_Invalid_Collection_Type();
    }

    collection = implementation.predictDeterministicAddress(_getSalt(creator, nonce));
  }

  /**
   * @notice [DEPRECATED] use `predictCollectionAddress` instead.
   * Returns the address of a collection given the current implementation version, creator, and nonce.
   * @param creator The creator of the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the collection contract that would be created by this nonce.
   * @dev This will return the same address whether the collection has already been created or not.
   */
  function predictNFTCollectionAddress(address creator, uint96 nonce) external view returns (address collection) {
    collection = predictCollectionAddress(CollectionType.NFTCollection, creator, nonce);
  }

  /**
   * @dev Salt is address + nonce packed.
   */
  function _getSalt(address creator, uint96 nonce) private pure returns (bytes32) {
    return bytes32((uint256(uint160(creator)) << 96) | uint256(nonce));
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This mixin is a total of 1,000 slots.
   */
  uint256[999] private __gap;
}