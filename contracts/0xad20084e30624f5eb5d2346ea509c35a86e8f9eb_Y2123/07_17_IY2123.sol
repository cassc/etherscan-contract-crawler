// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IY2123 is IERC721Enumerable {
  function mint(address recipient) external;

  function burn(uint256 tokenId) external;

  function updateOriginAccess(uint256[] memory tokenIds) external;

  function getTokenWriteBlock(uint256 tokenId) external view returns (uint64);

  function getAddressWriteBlock(address addr) external view returns (uint64);
}