// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Tiers
 * @dev A contract defining tiers for a token sale, each with specific details.
 * This contract defines an enum for different tiers and a struct to store details
 * for each tier, including the amount on sale, discount, lockup time, and purchase cap.
 */

contract Tiers {
    enum Tier {
        tier1,
        tier2,
        tier3,
        tier4
    }

    struct TierDetails {
        uint256 amountOnSale; // Total amount of tokens available for sale in this tier
        uint256 discount; // Discount percentage for this tier
        uint256 lockupTime; // Lockup period in seconds for tokens bought in this tier
        uint256 purchaseCap; // Maximum ETH that can be spent in this tier by a user
    }

    /**
     * @notice Converts a numerical tier value to its corresponding enum value.
     * @param tier The numerical value of the tier.
     * @return The corresponding Tier enum value.
     * @dev Use this function to convert a numerical tier value to its enum representation.
     * Reverts if the provided tier value is not valid.
     */
    function _t(uint256 tier) public pure returns (Tier) {
        if (tier == 1) {
            return Tier.tier1;
        } else if (tier == 2) {
            return Tier.tier2;
        } else if (tier == 3) {
            return Tier.tier3;
        } else if (tier == 4) {
            return Tier.tier4;
        } else {
            revert("Not valid tier");
        }
    }
}