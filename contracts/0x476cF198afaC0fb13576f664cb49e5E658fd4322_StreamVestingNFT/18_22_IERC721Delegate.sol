// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Delegate is IERC721, IERC721Enumerable {
  function balanceOfDelegate(address delegate) external view returns (uint256);

  function delegatedTo(uint256 tokenId) external view returns (address);

  function tokenOfDelegateByIndex(address delegate, uint256 index) external view returns (uint256);
}