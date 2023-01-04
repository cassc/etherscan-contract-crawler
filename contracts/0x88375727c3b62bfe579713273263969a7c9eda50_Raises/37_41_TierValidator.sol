// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TierParams} from "../../structs/Tier.sol";

error ValidationError(string message);

/// @title TierValidator - Tier parameter validator
library TierValidator {
    function validate(TierParams memory tier) internal pure {
        if (tier.supply == 0) {
            revert ValidationError("zero supply");
        }
        if (tier.limitPerAddress == 0) {
            revert ValidationError("zero limit");
        }
    }
}