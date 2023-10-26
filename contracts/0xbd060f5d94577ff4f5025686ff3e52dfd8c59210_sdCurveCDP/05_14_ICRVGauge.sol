// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICRVGauge {
    function deposit(uint256 _value) external;

    function withdraw(uint256 _value) external;

    function balanceOf(address account) external view returns (uint256);
}