// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IBalanceCalculator {
    function getUnderlying(address vault) external view returns (address);

    function calcValue(
        address vault,
        uint256 amount
    ) external view returns (uint256);
}