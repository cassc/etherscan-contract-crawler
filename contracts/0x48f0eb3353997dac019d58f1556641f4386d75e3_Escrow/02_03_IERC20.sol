// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}