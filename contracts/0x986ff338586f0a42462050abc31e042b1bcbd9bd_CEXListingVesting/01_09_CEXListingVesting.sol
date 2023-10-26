//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./VestingBase.sol";

contract CEXListingVesting is VestingBase {
    /* ========== CONSTRUCTOR ========== */
    constructor(
        address xox_,
        VestingInfo memory vestingInfo_,
        uint256 one_time_unlock_
    ) VestingBase(xox_, vestingInfo_, one_time_unlock_) {}
}