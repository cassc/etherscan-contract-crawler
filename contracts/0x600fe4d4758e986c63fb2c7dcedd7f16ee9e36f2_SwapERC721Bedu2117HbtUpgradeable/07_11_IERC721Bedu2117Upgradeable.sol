// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IERC721Bedu2117Upgradeable is IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    // public read methods
    function owner() external view returns (address);
    function getTotalSupply() external view returns (uint256);
    function exists(uint256 tokenId) external view returns (bool);
    function defaultURI() external view returns (string memory);
    function mainURI() external view returns (string memory);
    function getContractWorkModes() external view returns (bool mintingEnabled, bool transferEnabled, bool metadataRetrievalEnabled);
    function checkFrozenTokenStatusesBatch(uint256[] memory tokenIds) external view returns (bool[] memory frozenTokenStatuses);
    function isTrustedMinter(address account) external view returns (bool);
    function isTrustedAdmin(address account) external view returns (bool);
    function royaltyParams() external view returns (address royaltyAddress, uint256 royaltyPercent);
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);

    // public write methods
    function burn(uint256 tokenId) external;

    // trusted minter write methods
    function mintTokenBatchByTrustedMinter(address recipient, uint256 tokenCount) external;

    // trusted admin write methods
    function freezeTokenTransferBatchByTrustedAdmin(uint256[] memory tokenIds, bool freeze) external;
    function burnTokenBatchByTrustedAdmin(uint256[] memory tokenIds) external;

    // owner write methods
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    function setDefaultURI(string memory uri) external;
    function setMainURI(string memory uri) external;
    function setContractWorkModes(bool mintingEnabled, bool transferEnabled, bool metadataRetrievalEnabled) external;
    function updateTrustedMinterStatus(address account, bool isMinter) external;
    function updateTrustedAdminStatus(address account, bool isAdmin) external;
    function updateRoyaltyParams(address account, uint256 percent) external;
}