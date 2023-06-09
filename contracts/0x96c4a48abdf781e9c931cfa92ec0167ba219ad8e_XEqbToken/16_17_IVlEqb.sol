// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IRewards.sol";

interface IVlEqb is IRewards {
    function lock(address _user, uint256 _amount, uint256 _weeks) external;

    event LockCreated(address indexed _user, uint256 _amount, uint256 _weeks);

    event LockExtended(
        address indexed _user,
        uint256 _amount,
        uint256 _oldWeeks,
        uint256 _newWeeks
    );

    event Unlocked(
        address indexed _user,
        uint256 _amount,
        uint256 _lastUnlockedWeek
    );

    event RewardTokenAdded(address indexed _rewardToken);

    event RewardPaid(
        address indexed _user,
        address indexed _rewardToken,
        uint256 _reward
    );

    event AccessSet(address indexed _address, bool _status);
}