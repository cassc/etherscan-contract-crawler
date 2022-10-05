// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * IERC5114 Soul Badge interface
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

import "./IERC5114.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev See https://eips.ethereum.org/EIPS/eip-5114
 * This is additional interface on top of EIP-5114
 *
 * (bytes4) 0xb9d11845 = type(IERC5114SoulBadge).interfaceId
 */
interface IERC5114SoulBadge is IERC5114, IERC165, IERC721Metadata {
  // Returns badge token balance for a `Soul`
  function balanceOfSoul(address soulContract, uint256 soulTokenId) external view returns (uint256);

  // Returns the `Soul` token owner address
  function soulOwnerOf(uint256 tokenId) external view returns (address);
}