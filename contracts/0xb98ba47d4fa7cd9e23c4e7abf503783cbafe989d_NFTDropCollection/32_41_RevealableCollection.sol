// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

import "../roles/AdminRole.sol";

import "./ERC4906.sol";
import "./SharedURICollection.sol";

error RevealableCollection_Already_Revealed();

/**
 * @title Allow a collection to specify pre-reveal content which can later be revealed.
 * @dev Once the content has been revealed, it is immutable.
 * @author HardlyDifficult.
 */
abstract contract RevealableCollection is ERC4906, AdminRole, SharedURICollection {
  /// @notice Whether the collection is revealed or not.
  bool private $isRevealed;

  /**
   * @notice Emitted when the collection is revealed.
   * @param baseURI The base URI for the collection.
   * @param isRevealed Whether the collection is revealed.
   */
  event URIUpdated(string baseURI, bool isRevealed);

  /**
   * @notice Reverts if the collection has already been revealed.
   */
  modifier onlyWhileUnrevealed() {
    if ($isRevealed) {
      revert RevealableCollection_Already_Revealed();
    }
    _;
  }

  /**
   * @notice Allows the collection to be minted in either the final revealed state or as an unrevealed collection.
   */
  function _initializeRevealableCollection(bool _isRevealed) internal {
    $isRevealed = _isRevealed;
  }

  /**
   * @notice Allows a collection admin to reveal the collection's final content.
   * @dev Once revealed, the collection's content is immutable.
   * Use `updatePreRevealContent` to update content while unrevealed.
   * @param baseURI_ The base URI of the final content for this collection.
   */
  function reveal(string calldata baseURI_) external onlyAdmin onlyWhileUnrevealed {
    $isRevealed = true;

    _setBaseURI(baseURI_);
    emit URIUpdated(baseURI_, true);

    // All tokens in this collection have been updated.
    emit BatchMetadataUpdate(0, type(uint256).max);
  }

  /**
   * @notice Allows a collection admin to update the pre-reveal content.
   * @dev Use `reveal` to reveal the final content for this collection.
   * @param baseURI_ The base URI of the pre-reveal content.
   */
  function updatePreRevealContent(string calldata baseURI_) external onlyWhileUnrevealed onlyAdmin {
    _setBaseURI(baseURI_);
    emit URIUpdated(baseURI_, false);

    // All tokens in this collection have been updated.
    emit BatchMetadataUpdate(0, type(uint256).max);
  }

  /**
   * @notice Whether the collection is revealed or not.
   * @return revealed True if the final content has been revealed.
   */
  function isRevealed() external view returns (bool revealed) {
    revealed = $isRevealed;
  }

  /**
   * @inheritdoc IERC165Upgradeable
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC4906, AccessControlUpgradeable, ERC721Upgradeable) returns (bool isSupported) {
    isSupported = super.supportsInterface(interfaceId);
  }
}