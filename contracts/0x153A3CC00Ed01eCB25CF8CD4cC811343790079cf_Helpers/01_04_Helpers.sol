// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { wadDiv, wadMul } from "solmate/src/utils/SignedWadMath.sol";
import { InvalidCollateralType } from "./lib/Errors.sol";
import { CollateralType, Fee } from "./lib/Structs.sol";

library Helpers {
    int256 private constant _YEAR_WAD = 365 days * 1e18;
    uint256 private constant _LIQUIDATION_THRESHOLD = 100_000;
    uint256 private constant _BASIS_POINTS = 10_000;

    function bipsToSignedWads(uint256 bips) public pure returns (int256) {
        return int256((bips * 1e18) / _BASIS_POINTS);
    }

    function computeCurrentDebt(
        uint256 amount,
        uint256 rate,
        uint256 duration
    ) public pure returns (uint256) {
        int256 yearsWad = wadDiv(int256(duration) * 1e18, _YEAR_WAD);
        return
            amount +
            uint256(
                wadMul(int256(amount), wadMul(yearsWad, bipsToSignedWads(rate)))
            );
    }

    function computeAmountAfterFees(
        uint256 amount,
        Fee[] memory fees
    ) public pure returns (uint256 netAmount) {
        netAmount = amount;
        for (uint256 i = 0; i < fees.length; i++) {
            netAmount = netAmount - computeFeeAmount(amount, fees[i].rate);
        }
        return netAmount;
    }

    function computeFeeAmount(
        uint256 amount,
        uint16 rate
    ) public pure returns (uint256) {
        return ((amount * rate) + _BASIS_POINTS - 1) / _BASIS_POINTS;
    }
}