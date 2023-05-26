// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract IERC1155 {
    function balanceOf(address owner, uint256 index) external virtual view returns (uint256 balance);
}