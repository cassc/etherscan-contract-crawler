// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "../../libraries/ShortStrings.sol";

import "../../interfaces/internal/INFTCollectionType.sol";

/**
 * @title A mixin to add the NFTCollectionType interface to a contract.
 * @author HardlyDifficult & reggieag
 */
abstract contract NFTCollectionType is INFTCollectionType, ERC165Upgradeable {
  using ShortStrings for string;
  using ShortStrings for ShortString;

  ShortString private immutable _collectionTypeName;

  constructor(string memory collectionTypeName) {
    _collectionTypeName = collectionTypeName.toShortString();
  }

  /**
   * @notice Returns a name of the type of collection this contract represents.
   * @return collectionType The collection type.
   */
  function getNFTCollectionType() external view returns (string memory collectionType) {
    collectionType = _collectionTypeName.toString();
  }

  /**
   * @inheritdoc IERC165Upgradeable
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool interfaceSupported) {
    interfaceSupported = interfaceId == type(INFTCollectionType).interfaceId || super.supportsInterface(interfaceId);
  }
}