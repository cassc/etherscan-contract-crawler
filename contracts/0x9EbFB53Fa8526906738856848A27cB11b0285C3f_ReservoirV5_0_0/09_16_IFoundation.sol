// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFoundation {
    function buyV2(
        address nftContract,
        uint256 tokenId,
        uint256 maxPrice,
        address referrer
    ) external payable;
}