// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface ICvxLocker {
    struct LockedBalance {
        uint112 amount;
        uint112 boosted;
        uint32 unlockTime;
    }
    struct EarnedData {
        address token;
        uint256 amount;
    }

    function lock(
        address _account,
        uint256 _amount,
        uint256 _spendRatio
    ) external;

    function lockedBalances(address _user)
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        );

    function processExpiredLocks(bool _relock) external;

    function claimableRewards(address _account)
        external
        view
        returns (EarnedData[] memory userRewards);

    function getReward(address _account, bool _stake) external;

    function lockedBalanceOf(address _user)
        external
        view
        returns (uint256 amount);
}