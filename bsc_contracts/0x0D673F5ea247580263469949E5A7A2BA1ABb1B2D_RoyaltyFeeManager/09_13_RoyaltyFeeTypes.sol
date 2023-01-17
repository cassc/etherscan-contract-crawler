// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RoyaltyFeeTypes
 * @notice This library contains types related to royalty fees
 */
library RoyaltyFeeTypes {
    struct FeeInfoPart {
        address receiver;
        uint256 fee;
    }

    struct FeeAmountPart {
        address receiver;
        uint256 amount;
    }
}