// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IPriceOracle {
    function decimals() external view returns (uint256 _decimals);

    function latestAnswer() external view returns (uint256 price);
}