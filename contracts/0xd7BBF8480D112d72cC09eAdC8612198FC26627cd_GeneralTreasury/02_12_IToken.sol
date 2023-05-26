// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IToken {
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);
}