// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "../shared/Constants.sol";

enum CollectionType {
  // Reserve 0 to indicate undefined.
  NULL,
  NFTCollection,
  NFTDropCollection,
  NFTTimedEditionCollection
}

error NFTCollectionFactoryTypes_Collection_Type_Is_Null();

/**
 * @title A mixin to define the types of collections supported by this factory.
 */
abstract contract NFTCollectionFactoryTypes {
  /**
   * @notice Returns the maximum value of the CollectionType enum.
   * @return count The maximum value of the CollectionType enum.
   * @dev Templates are indexed from 1 to this value inclusive.
   */
  function getCollectionTypeCount() external pure returns (uint256 count) {
    count = uint256(type(CollectionType).max);
  }

  /**
   * @notice Returns the name of the collection type.
   * @param collectionType The enum index collection type to check.
   * @return typeName The name of the collection type.
   */
  function getCollectionTypeName(CollectionType collectionType) public pure returns (string memory typeName) {
    if (collectionType == CollectionType.NFTCollection) {
      typeName = NFT_COLLECTION_TYPE;
    } else if (collectionType == CollectionType.NFTDropCollection) {
      typeName = NFT_DROP_COLLECTION_TYPE;
    } else if (collectionType == CollectionType.NFTTimedEditionCollection) {
      typeName = NFT_TIMED_EDITION_COLLECTION_TYPE;
    } else {
      // if (collectionType == CollectionType.NULL)
      revert NFTCollectionFactoryTypes_Collection_Type_Is_Null();
    }
  }

  // This mixin consumes 0 slots.
}