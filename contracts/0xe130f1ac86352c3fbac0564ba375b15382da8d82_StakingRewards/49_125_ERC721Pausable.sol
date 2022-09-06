// SPDX-License-Identifier: MIT
// solhint-disable
/*
  Vendored from @openzeppelin/[email protected]
  Alterations:
   * Use vendored ERC721, which inherits from vendored ERC165 with virtual supportsInterface
*/

pragma solidity ^0.6.0;

import "./ERC721.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721PausableUpgradeSafe is Initializable, ERC721UpgradeSafe, PausableUpgradeSafe {
  function __ERC721Pausable_init() internal initializer {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __Pausable_init_unchained();
    __ERC721Pausable_init_unchained();
  }

  function __ERC721Pausable_init_unchained() internal initializer {}

  /**
   * @dev See {ERC721-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    require(!paused(), "ERC721Pausable: token transfer while paused");
  }

  uint256[50] private __gap;
}