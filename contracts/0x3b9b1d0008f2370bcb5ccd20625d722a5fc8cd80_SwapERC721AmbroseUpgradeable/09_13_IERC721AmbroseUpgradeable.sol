// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IERC721AmbroseUpgradeable is IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    // public read methods
    function owner() external view returns (address);
    function getOwner() external view returns (address);
    function paused() external view returns (bool);
    function exists(uint256 tokenId) external view returns (bool);
    function metadataInfo() external view returns (bool metadataLocked, string memory defaultUri, string memory mainUri);
    function randomDataInfo() external view returns (bool randomDataLocked, uint256 randomData);
    function getMaxTotalSupply() external view returns (uint256);
    function getTotalSupply() external view returns (uint256);
    function stats() external view returns (uint256 maxTotalSupply, uint256 totalSupply, uint256 supplyLeft);
    function isTrustedMinter(address account) external view returns (bool);
    function royaltyParams() external view returns (address royaltyAddress, uint256 royaltyPercent);
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);

    // public write methods
    function burn(uint256 tokenId) external;

    // trusted minter write methods
    function mintTokenBatch(address recipient, uint256 tokenCount) external;
}