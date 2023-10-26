// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDividends {
    function allocate(address userAddress, uint256 amount) external;

    function deallocate(address userAddress, uint256 amount) external;
}