// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILock {
    function lock(address userAddress, address tokenAddress, uint256 tokenAmount) external;
    function claim(address tokenAddress) external;
}