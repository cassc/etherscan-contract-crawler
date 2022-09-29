// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IYearn {
    function deposit(uint256) external returns (uint256);

    function withdraw(uint256) external returns (uint256);

    function pricePerShare() external returns (uint256);
}