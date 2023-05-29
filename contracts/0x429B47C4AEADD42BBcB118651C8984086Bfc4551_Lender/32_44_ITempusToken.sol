// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface ITempusToken {
    function balanceOf(address) external returns (uint256);

    function pool() external view returns (address);
}