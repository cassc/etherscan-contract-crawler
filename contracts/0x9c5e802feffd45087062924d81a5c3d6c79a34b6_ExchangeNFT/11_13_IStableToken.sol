// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStableToken {
    function allowance(address owner, address spender) external returns (uint);
    function transferFrom(address sender, address recipient, uint256 amount) external;
}