// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721AUpgradeable} from "@erc721a-upgradable/extensions/ERC721AQueryableUpgradeable.sol";

interface IBeepBoopInjectable is IERC721AUpgradeable {
    event Mint(uint256 fromTokenId, uint256 toTokenId, uint256 type_);

    function burn(uint256 tokenId) external;

    function getInjectorType(uint256 tokenId) external view returns (uint256);
}