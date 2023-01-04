// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./IAggregationExecutor.sol";
import {SwapDescription} from "./structs.sol";

interface IAggregationRouterV4 {
    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (
            uint256 returnAmount,
            uint256 spentAmount,
            uint256 gasLeft
        );
}