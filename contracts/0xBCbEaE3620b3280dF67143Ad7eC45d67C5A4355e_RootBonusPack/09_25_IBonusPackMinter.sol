// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBonusPackMinter {
    function allocatedBonusPacks(uint256 tokenId) external view returns (address);
}