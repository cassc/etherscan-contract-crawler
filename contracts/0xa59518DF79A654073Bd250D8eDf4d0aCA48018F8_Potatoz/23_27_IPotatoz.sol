// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPotatoz {
    function isPotatozStaking(uint256 tokenId) external view returns (bool);

    function stakeExternal(uint256 tokenId) external;

    function nftOwnerOf(uint256 tokenId) external view returns (address);
}