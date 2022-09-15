// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVeDist {
    function claim(uint256) external returns (uint256);
}