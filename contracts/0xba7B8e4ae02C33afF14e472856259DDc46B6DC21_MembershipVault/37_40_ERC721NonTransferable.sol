// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";

/**
 * @title A read only ERC721 token
 * @notice A abstract registry of NFTs that only allows reading the NFTs and nothing
 *         else (no minting, transferring, etc). This acts as a "view" into some set
 *         of NFTs that may not otherwise adhere to the ERC721 standard.
 * @dev See `Transfer Mechanism` in the following link for the inspiration
 *      behind this class: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md#rationale
 */

abstract contract ERC721NonTransferable is IERC721Upgradeable {
  // Throw if a mutating function is called
  error ReadOnly();

  function safeTransferFrom(
    address,
    address,
    uint256
  ) external pure {
    revert ReadOnly();
  }

  function transferFrom(
    address,
    address,
    uint256
  ) external pure {
    revert ReadOnly();
  }

  function approve(address, uint256) external pure {
    revert ReadOnly();
  }

  function getApproved(uint256) external pure returns (address) {
    revert ReadOnly();
  }

  function setApprovalForAll(address, bool) external pure {
    revert ReadOnly();
  }

  function isApprovedForAll(address, address) external pure returns (bool) {
    revert ReadOnly();
  }

  function safeTransferFrom(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure {
    revert ReadOnly();
  }
}