// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IERC721RewardByTier is IERC721Enumerable   {
    function tierOf(uint256 tokenId) external view returns (uint8);
    function startOwnerOf(uint256 tokenId) external view returns (uint256);
    function updateTier(uint256 tokenId, uint8 newTier) external;
}