// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWithBalance {
    function balanceOf(address owner) external view returns (uint256);
}