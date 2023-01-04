// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {RaiseParams, RaiseState} from "../../structs/Raise.sol";
import {ITokenAuth} from "../../interfaces/ITokenAuth.sol";
import {ETH} from "../../constants/Constants.sol";

error ValidationError(string message);

library RaiseValidator {
    function validate(RaiseParams memory params, address allowlist) internal view {
        // Currency must be allowlisted
        if (params.currency != ETH) {
            if (ITokenAuth(allowlist).denied(params.currency)) revert ValidationError("invalid token");
        }
        // Zero max means "no maximum"
        if (params.max > 0) {
            // The raise goal cannot be greater than the raise max
            if (params.max < params.goal) {
                revert ValidationError("max < goal");
            }
        }
        // End times must be after start times
        if (params.presaleEnd < params.presaleStart) {
            revert ValidationError("end < start");
        }
        if (params.publicSaleEnd <= params.publicSaleStart) {
            revert ValidationError("end <= start");
        }
        // Public start must be equal to or after presale end
        if (params.publicSaleStart < params.presaleEnd) {
            revert ValidationError("public < presale");
        }
        // Start time must be now or in future. Since we know public start
        // is after presale end and all end times are after start times,
        // we only have to check presale start here.
        if (params.presaleStart < block.timestamp) {
            revert ValidationError("start <= now");
        }
        // Max length of phases is 1 year
        if (params.presaleEnd - params.presaleStart > 365 days) {
            revert ValidationError("too long");
        }
        if (params.publicSaleEnd - params.publicSaleStart > 365 days) {
            revert ValidationError("too long");
        }
    }
}