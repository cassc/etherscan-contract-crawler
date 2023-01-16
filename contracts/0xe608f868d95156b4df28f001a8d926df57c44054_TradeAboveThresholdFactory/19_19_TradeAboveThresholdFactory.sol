// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../TradeAboveThreshold.sol";

// @title A factory to create `TradeAboveThreshold` order instances
contract TradeAboveThresholdFactory {
    GPv2Settlement public constant SETTLEMENT_CONTRACT =
        GPv2Settlement(0x9008D19f58AAbD9eD0D60971565AA8510560ab41);

    function create(
        IERC20 sellToken,
        IERC20 buyToken,
        address target,
        uint256 threshold
    ) external returns (TradeAboveThreshold) {
        return
            new TradeAboveThreshold(
                sellToken,
                buyToken,
                target,
                threshold,
                SETTLEMENT_CONTRACT
            );
    }
}