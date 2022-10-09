// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ISudoPool {
    function getBuyNFTQuote(uint) external view returns (uint8, uint, uint, uint, uint);
}