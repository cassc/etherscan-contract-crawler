// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { PERCENTAGE_FACTOR } from "@gearbox-protocol/core-v2/contracts/libraries/PercentageMath.sol";

library SlippageMath {
    function applySlippage(
        uint256 amount,
        uint256 slippage,
        bool isExactInput
    ) internal pure returns (uint256) {
        if (isExactInput) {
            return
                (amount * (PERCENTAGE_FACTOR - slippage)) / PERCENTAGE_FACTOR;
        } else {
            return
                (amount * (PERCENTAGE_FACTOR + slippage)) / PERCENTAGE_FACTOR;
        }
    }

    function applySlippage(
        uint256 amount,
        uint256 slippage,
        uint256 numSteps,
        bool isExactInput
    ) internal pure returns (uint256) {
        if (isExactInput) {
            return
                (amount * ((PERCENTAGE_FACTOR - slippage))**numSteps) /
                (uint256(PERCENTAGE_FACTOR)**numSteps);
        } else {
            return
                (amount * ((PERCENTAGE_FACTOR + slippage))**numSteps) /
                (uint256(PERCENTAGE_FACTOR)**numSteps);
        }
    }
}