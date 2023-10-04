// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {BalancerDataTypes} from "./BalancerDataTypes.sol";

interface IBalancerVault {
    function swap(
        BalancerDataTypes.SingleSwap memory singleSwap,
        BalancerDataTypes.FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);
}