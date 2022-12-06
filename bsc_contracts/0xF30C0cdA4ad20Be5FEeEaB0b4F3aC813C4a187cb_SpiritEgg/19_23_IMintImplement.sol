// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMintImplement {
    function mint(address to, uint128 period, uint128 round, uint256[] calldata tokenIds) external;

    function batchMint(address to, uint128 period, uint128 round, uint256 startTokenId, uint128 amount) external;

    function mint(address to) external;

    function airdrop(address to, uint256 tokenId) external;
}