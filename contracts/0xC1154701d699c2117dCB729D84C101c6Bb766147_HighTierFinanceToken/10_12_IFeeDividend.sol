// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFeeDividend {
    function distributeFee() external;
    function getTax() external view returns (uint256, uint256);
}