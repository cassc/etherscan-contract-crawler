// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IStrip {
    function balanceOf(address account) external view returns (uint256);
    function buy(uint price) external;
    function decimals() external view returns (uint);
}