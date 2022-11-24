// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAnyswapToken {
    function underlying() external returns (address);

    // to not EVM
    function Swapout(uint256 amount, string memory bindaddr) external returns (bool);

    // to EVM
    function Swapout(uint256 amount, address bindaddr) external returns (bool);
}