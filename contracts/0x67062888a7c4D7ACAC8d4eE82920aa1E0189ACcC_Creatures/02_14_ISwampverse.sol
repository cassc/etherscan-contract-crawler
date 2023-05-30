// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISwampverse {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}