// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IPendingCommissions {
    struct DistributionInfo {
        address user;
        uint256 amount;
    }

    function updateRewards(
        uint256,
        bool,
        uint256,
        DistributionInfo[] memory
    ) external;

    function claimInternally(
        uint256,
        address
    ) external;

}