// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title StreetlabERC721ABurnable
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract StreetlabERC721ABurnable is
  ERC721AUpgradeable,
  OwnableUpgradeable
{
  /// @notice Whether burning is enabled or not
  bool public burnEnabled;

  /////////////////////////////////////////////////
  /// External Functions                         //
  /////////////////////////////////////////////////

  /**
   * @notice Burn token if enabled
   * @param tokenId to burn
   */
  function burn(uint256 tokenId) external {
    require(burnEnabled, "Burning is disabled.");
    _burn(tokenId, true);
  }

  /**
   * @notice Burn multiple tokens if enabled
   * @param tokenIds to burn
   */
  function burnBatch(uint256[] calldata tokenIds) external {
    require(burnEnabled, "Burning is disabled.");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _burn(tokenIds[i], true);
    }
  }

  /// @notice Allow the owner to toggle burn
  function toggleBurn() external onlyOwner {
    burnEnabled = !burnEnabled;
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}