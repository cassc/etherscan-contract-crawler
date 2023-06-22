// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAggregatorV3} from "./IAggregatorV3.sol";

interface ISDYCOracle is IAggregatorV3 {
    function totalInterestAccrued() external returns (uint256);
}