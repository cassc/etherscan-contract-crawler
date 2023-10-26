// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/// @title A mechanism for calculating uAR received for a dollar amount burnt
interface IUARForDollarsCalculator {
    function getUARAmount(uint256 dollarsToBurn, uint256 blockHeightDebt)
        external
        view
        returns (uint256);
}