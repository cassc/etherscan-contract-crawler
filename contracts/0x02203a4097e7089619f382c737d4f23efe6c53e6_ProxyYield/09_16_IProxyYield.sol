// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IProxyYield {
    event Withdraw(address indexed userAddress, uint256 amount, uint256 tax);
    event BribeClaim(address indexed to, uint256 amount);

    function withdraw(
        uint256 amount
    ) external;

    function getTaxRate(address user) external view returns (uint256);
}