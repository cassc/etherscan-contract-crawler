// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IBlackOrbMetadata{
    function generateMetadata(uint tokenId, bool bhc, uint64 balance, uint64 paid, uint64 highestPaidAtMint, address minter, uint64 balanceRequired) external view returns(string memory);
}