// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IWETH {
    function withdraw(uint256 amount) external;

    function balanceOf(address user) view external returns(uint256);
}