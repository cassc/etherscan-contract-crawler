// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILockAura {
    struct LockedBalance {
        uint112 amount;
        uint32 unlockTime;
    }

    struct EarnedData {
        address token;
        uint256 amount;
    }

    function getReward(address _account) external;

    function processExpiredLocks(bool _relock) external;

    function lock(address _account, uint256 _amount) external;

    function claimableRewards(address _account)
        external
        view
        returns (EarnedData[] memory userRewards);

    function lockedBalances(address _user)
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        );
}