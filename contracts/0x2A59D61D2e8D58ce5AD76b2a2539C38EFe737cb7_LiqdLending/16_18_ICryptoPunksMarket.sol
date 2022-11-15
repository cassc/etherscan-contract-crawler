// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface ICryptoPunksMarket {
    function buyPunk(uint256 punkIndex) external payable;

    function transferPunk(address to, uint256 punkIndex) external;
}