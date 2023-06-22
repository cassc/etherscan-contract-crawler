// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IRFOXFactory {
    function createNFT() external returns (address pair);
}