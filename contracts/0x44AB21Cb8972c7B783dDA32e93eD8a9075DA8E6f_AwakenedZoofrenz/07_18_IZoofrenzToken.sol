// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IZoofrenzToken is IERC721Metadata {
    function isTokenExist(uint256 tokenId) external view returns (bool);
    function isOwner(uint256 tokenId) external view returns (bool);
    function frenzRarities(uint256) external view returns (uint256);
}