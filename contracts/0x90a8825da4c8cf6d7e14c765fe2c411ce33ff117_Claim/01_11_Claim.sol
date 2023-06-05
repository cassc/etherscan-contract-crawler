// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./claim/VestedClaim.sol";

contract Claim is VestedClaim {

    event ClaimantsAdded(
        address[] indexed claimants,
        uint256[] indexed amounts
    );

    event RewardsFrozen(
        address[] indexed claimants
    );

    constructor(uint256 _claimTime, ERC20 _token) VestedClaim(_token) {
        claimTime = _claimTime;
    }

    function updateClaimTimestamp(uint256 _claimTime) external onlyOwner {
        claimTime = _claimTime;
    }

    function addClaimants(
        address[] memory _claimants,
        uint256[] memory _claimAmounts
    ) external onlyOwner {
        require(
            _claimants.length == _claimAmounts.length,
            "Arrays do not have equal length"
        );

        for (uint256 i = 0; i < _claimants.length; i++) {
            setUserReward(_claimants[i], _claimAmounts[i]);
        }

        emit ClaimantsAdded(_claimants, _claimAmounts);
    }

    function freezeRewards(
        address[] memory _claimants
    ) external onlyOwner {
        for (uint256 i = 0; i < _claimants.length; i++) {
            freezeUserReward(_claimants[i]);
        }

        emit RewardsFrozen(_claimants);
    }
}