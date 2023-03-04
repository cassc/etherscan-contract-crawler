// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title A placeholder contract skipping slots previously consumed by the NFTCollectionFactory upgradeable contract.
 * @author batu-inal & HardlyDifficult
 */
abstract contract NFTCollectionFactoryV1Gap {
  // Previously stored in these slots:
  // uint256[10_000] private __gap;
  //
  // /****** Slot 0 (after inheritance) ******/
  // /**
  //  * @notice The address of the implementation all new NFTCollections will leverage.
  //  * @dev When this is changed, `versionNFTCollection` is incremented.
  //  * @return The implementation address for NFTCollection.
  //  */
  // address public implementationNFTCollection;

  // /**
  //  * @notice The implementation version of new NFTCollections.
  //  * @dev This is auto-incremented each time `implementationNFTCollection` is changed.
  //  * @return The current NFTCollection implementation version.
  //  */
  // uint32 public versionNFTCollection;

  // /****** Slot 1 ******/
  // /**
  //  * @notice The address of the implementation all new NFTDropCollections will leverage.
  //  * @dev When this is changed, `versionNFTDropCollection` is incremented.
  //  * @return The implementation address for NFTDropCollection.
  //  */
  // address public implementationNFTDropCollection;

  // /**
  //  * @notice The implementation version of new NFTDropCollections.
  //  * @dev This is auto-incremented each time `implementationNFTDropCollection` is changed.
  //  * @return The current NFTDropCollection implementation version.
  //  */
  // uint32 public versionNFTDropCollection;

  // /****** End of storage ******/

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[10_002] private __gap;
}