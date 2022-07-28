// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface ICryptoPunksMarket {
    function buyPunk(uint punkIndex) external payable;
    function transferPunk(address to, uint punkIndex) external;
}