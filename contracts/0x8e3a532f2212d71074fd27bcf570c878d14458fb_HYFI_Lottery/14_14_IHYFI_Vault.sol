// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IHYFI_Vault is IAccessControlUpgradeable {
    function MINTER_ROLE() external view returns (bytes32);

    function BURNER_ROLE() external view returns (bytes32);

    function safeMint(address to, uint256 amount) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}