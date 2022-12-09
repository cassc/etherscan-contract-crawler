// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IAuraLocker {
    struct EarnedData {
        address token;
        uint256 amount;
    }

    struct Balances {
        uint112 locked;
        uint32 nextUnlockIndex;
    }

    struct LockedBalance {
        uint112 amount;
        uint32 unlockTime;
    }

    struct Epoch {
        uint224 supply;
        uint32 date; //epoch start date
    }

    function lock(address _account, uint256 _amount) external;

    function getReward(address _account) external;

    function getReward(address _account, bool _stake) external;

    function claimableRewards(address _account)
        external
        view
        returns (EarnedData[] memory userRewards);

    function rewardTokens(uint256 _index) external view returns (address token);

    function rewardPerToken(address _rewardsToken)
        external
        view
        returns (uint256);

    function lastTimeRewardApplicable(address _rewardsToken)
        external
        view
        returns (uint256);

    //BOOSTED balance of an account which only includes properly locked tokens as of the most recent eligible epoch
    function balanceOf(address _user) external view returns (uint256 amount);

    function balanceAtEpochOf(uint256 _epoch, address _user)
        external
        view
        returns (uint256 amount);

    function balances(address _user)
        external
        view
        returns (Balances memory bals);

    function userLocks(address _user, uint256 _index)
        external
        view
        returns (LockedBalance memory lockedBals);

    function lockedBalances(address _user)
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        );

    function findEpochId(uint256 _time) external view returns (uint256 epoch);

    function epochs(uint256 _index) external view returns (Epoch memory epoch);

    function lockedSupply() external view returns (uint256);

    // Withdraw/relock all currently locked tokens where the unlock time has passed
    function processExpiredLocks(
        bool _relock,
        uint256 _spendRatio,
        address _withdrawTo
    ) external;

    // Withdraw/relock all currently locked tokens where the unlock time has passed
    function processExpiredLocks(bool _relock) external;

    function delegate(address newDelegatee) external;

    function delegates(address account) external view returns (address);
}