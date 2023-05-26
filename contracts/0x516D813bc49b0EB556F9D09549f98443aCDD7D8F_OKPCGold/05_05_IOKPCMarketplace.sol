// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface IOKPCMarketplace {
    function didMint(uint256 pcId, uint256 artId) external view returns (bool);
}