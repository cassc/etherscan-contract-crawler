// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721BalanceOf {
    function balanceOf(address owner) external view returns(uint256);
}