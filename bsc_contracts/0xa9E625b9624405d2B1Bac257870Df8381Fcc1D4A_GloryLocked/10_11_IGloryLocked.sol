// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IGloryLocked {
    function balanceOf(address account) external view returns (uint256);

    function stakeGlory(address account, uint256 amount) external;
}