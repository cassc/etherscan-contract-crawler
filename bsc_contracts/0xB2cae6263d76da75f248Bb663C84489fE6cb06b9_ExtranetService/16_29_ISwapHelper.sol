// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ISwapHelper {
    function swap(address from, address to, address recipient)
        external
        returns (uint256);
}