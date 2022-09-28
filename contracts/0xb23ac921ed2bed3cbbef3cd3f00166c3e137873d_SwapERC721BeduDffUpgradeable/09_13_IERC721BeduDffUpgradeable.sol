// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IERC721BeduDffUpgradeable is IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    // Global transfer mode: 0 - AnyTransferForbidden, 1 - AnyTransferAllowed, 2 - TransferAllowedPerTokenSettings
    enum GlobalTransferMode {
        AnyTransferForbidden,
        AnyTransferAllowed,
        TransferAllowedPerTokenSettings
    }
    // Token transfer mode: 0 - AnyTransferForbidden, 1 - AnyTransferAllowed, 2 - TransferAllowedToSingleAddress
    enum TokenTransferMode {
        AnyTransferForbidden,
        AnyTransferAllowed,
        TransferAllowedToSingleAddress
    }

    // public read methods
    function owner() external view returns (address);
    function getOwner() external view returns (address);
    function paused() external view returns (bool);
    function exists(uint256 tokenId) external view returns (bool);
    function defaultURI() external view returns (string memory);
    function getTotalSupply() external view returns (uint256);
    function royaltyParams() external view returns (address royaltyAddress, uint256 royaltyPercent);
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
    function isTrustedMinter(address account) external view returns (bool);
    function isTrustedAdmin(address account) external view returns (bool);
    function globalTransferMode() external view returns (GlobalTransferMode);
    function getTokenTransferSettingsBatch(uint256[] memory tokenIds) external view returns (TokenTransferMode[] memory transferModeList, address[] memory singleAddressList);
    function checkTokenTransferAvailability(uint256 tokenId, address transferTo) external view returns (bool);

    // public write methods
    function burn(uint256 tokenId) external;

    // trusted minter write methods
    function mintTokenBatch(address recipient, uint256 tokenCount) external;

    // trusted admin write methods
    function updateGlobalTransferMode(GlobalTransferMode transferMode) external;
    function updateTokenTransferSettingsBatch(uint256[] memory tokenIds, TokenTransferMode transferMode, address singleAddress) external;
}