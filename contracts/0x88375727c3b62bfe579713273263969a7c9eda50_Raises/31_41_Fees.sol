// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {FeeSchedule} from "../structs/Raise.sol";
import {TierType} from "../structs/Tier.sol";

uint256 constant BPS_DENOMINATOR = 10_000;

error ValidationError(string message);

/// @title Fees - Fee calculator
/// @notice Calculates protocol fee based on token mint price.
library Fees {
    function validate(FeeSchedule memory fees) internal pure {
        if (fees.fanFee >= BPS_DENOMINATOR) {
            revert ValidationError("invalid fanFee");
        }
        if (fees.brandFee >= BPS_DENOMINATOR) {
            revert ValidationError("invalid brandFee");
        }
    }

    function calculate(FeeSchedule storage fees, TierType tierType, uint256 mintPrice)
        internal
        view
        returns (uint256 protocolFee, uint256 creatorTake)
    {
        uint256 feeBps = (tierType == TierType.Fan) ? fees.fanFee : fees.brandFee;
        protocolFee = (feeBps * mintPrice) / BPS_DENOMINATOR;
        creatorTake = mintPrice - protocolFee;
    }
}