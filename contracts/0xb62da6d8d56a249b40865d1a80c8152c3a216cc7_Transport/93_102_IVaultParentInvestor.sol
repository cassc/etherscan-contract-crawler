// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IVaultParentInvestor {
    function withdrawMultiChain(
        uint tokenId,
        uint amount,
        uint[] memory lzFees
    ) external;

    function withdrawAllMultiChain(uint tokenId, uint[] memory lzFees) external;

    function requestTotalValueUpdateMultiChain(uint[] memory lzFees) external;
}