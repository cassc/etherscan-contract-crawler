//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IGenesisNFT is IERC721Upgradeable {
    event Mint(address owner, uint256 tokenId);
    event Burn(uint256 tokenId);

    function lockGenesisNFT(
        address onBehalfOf,
        address caller,
        uint256 tokenId
    ) external returns (uint256);

    function unlockGenesisNFT(uint256 tokenId) external;
}