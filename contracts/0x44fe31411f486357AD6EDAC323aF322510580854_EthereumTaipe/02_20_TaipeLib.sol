// SPDX-License-Identifier: MIT
// Taipe Experience Contracts
pragma solidity ^0.8.9;

library TaipeLib {
    uint constant TOTAL_TIER_1 = 25;
    uint constant TOTAL_TIER_2 = 4500;
    uint constant TOTAL_TIER_3 = 7475;

    enum Tier {
        TIER_1,
        TIER_2,
        TIER_3
    }

    function getStartingId(Tier tier) internal pure returns (uint) {
        if (tier == Tier.TIER_1) return 0;
        else if (tier == Tier.TIER_2) return TOTAL_TIER_1;
        return TOTAL_TIER_1 + TOTAL_TIER_2;
    }

    function getAvailableCount(Tier tier) internal pure returns (uint) {
        if (tier == Tier.TIER_1) return TOTAL_TIER_1;
        else if (tier == Tier.TIER_2) return TOTAL_TIER_2;
        return TOTAL_TIER_3;
    }
}