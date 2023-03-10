// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../ClaimConfigurable.sol";

contract GptClaim is ClaimConfigurable {
    constructor(
        uint256 _claimTime,
        address _token,
        uint256[4] memory vestingData
    ) ClaimConfigurable(_claimTime, _token, vestingData) {}
}