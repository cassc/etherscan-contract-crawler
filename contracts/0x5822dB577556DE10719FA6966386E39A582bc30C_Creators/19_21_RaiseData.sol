// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TierType} from "./Tier.sol";

/// @param projectId Integer ID of the project associated with this raise token.
/// @param raiseId Integer ID of the raise associated with this raise token.
/// @param tierId Integer ID of the tier associated with this raise token.
/// @param tierType Enum indicating whether this is a "fan" or "brand" token.
struct RaiseData {
    uint32 projectId;
    uint32 raiseId;
    uint32 tierId;
    TierType tierType;
}