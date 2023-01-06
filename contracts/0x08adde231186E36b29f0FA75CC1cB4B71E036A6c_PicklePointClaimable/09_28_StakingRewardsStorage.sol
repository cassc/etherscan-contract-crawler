// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StakingRewardsStorage {
    struct Layout {
        mapping(address => uint256) pointsPerDay;
        mapping(address => uint256) claimedByUser;
        mapping(address => uint256) claimableByUser;
    }

    bytes32 internal constant APP_STORAGE_SLOT =
        keccak256("NiftyKit.contracts.StakingRewards");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = APP_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}