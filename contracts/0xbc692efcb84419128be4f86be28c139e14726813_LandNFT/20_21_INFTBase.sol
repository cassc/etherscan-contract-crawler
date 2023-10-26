// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";

// interface for INFTBase
interface INFTBase is IERC1155Upgradeable, IAccessControlUpgradeable {
    function burn(uint256 tokenId, uint256 amount) external;
    
    function mint(address maker, uint256 tokenId, uint256 amount) external returns(uint256);
    function mintBatch(address maker, uint256[] memory tokenIds, uint256[] memory amounts) external returns(uint256[] memory);

    function getTotalSupply(uint256 tokenId) external view returns (uint256);
}