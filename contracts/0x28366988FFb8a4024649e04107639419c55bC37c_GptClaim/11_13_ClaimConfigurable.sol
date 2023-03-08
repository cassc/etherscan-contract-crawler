// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Claim.sol";

contract ClaimConfigurable is Claim {
    constructor(
        uint256 _claimTime,
        address _token,
        uint256[4] memory vestingData
    ) Claim(_claimTime, _token) {
        require(vestingData[0] <= BASE_POINTS, "initialUnlock too high");

        initialUnlock = vestingData[0];
        cliff = vestingData[1];
        vesting = vestingData[2];
        vestingInterval = vestingData[3];
    }
}