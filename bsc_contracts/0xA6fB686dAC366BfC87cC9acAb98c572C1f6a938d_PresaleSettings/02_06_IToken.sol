// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IToken {
    function getFee() external returns (uint256);
    function getOwnedBalance(address account) external view returns (uint);
}