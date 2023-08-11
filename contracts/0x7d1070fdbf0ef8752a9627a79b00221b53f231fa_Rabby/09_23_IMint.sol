// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IMintNFT {
    function mintFor(address to, uint64 numTokens) external;

    function transferBundle(
        address to,
        uint256 startingIndex,
        uint64 numTokens
    ) external;
}