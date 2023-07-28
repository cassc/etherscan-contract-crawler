// SPDX-License-Identifier: MIT

// MUST STAKE AT LEAST 1 TIME BEFORE SETTING REWARDS!!

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITopiaLpStaking.sol";

contract TopiaLpStaking is ITopiaLpStaking, Ownable {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    bool public rewardsSet;
    IERC20 public immutable rewardsToken;
    IERC20 public immutable stakingToken;
    RewardsPeriod public rewardsPeriod;
    RewardsPerWeight public rewardsPerWeight;
    uint32[] public lockupIntervals; // timestamps for duration of lockups available
    uint8[] public lockupIntervalMultipliers; // lockup multiplier, must match lockup intervals array length
    mapping(address => ITopiaLpStaking.UserStake[]) public userStakes;

    constructor(
        IERC20 _rewardsToken,
        IERC20 _stakingToken,
        uint32[] memory _lockupIntervals,
        uint8[] memory _lockupIntervalMultipliers
    ) {
        if (_lockupIntervals.length != _lockupIntervalMultipliers.length) {
            revert IntervalsMismatch();
        }

        rewardsToken = _rewardsToken;
        stakingToken = _stakingToken;
        lockupIntervals = _lockupIntervals;
        lockupIntervalMultipliers = _lockupIntervalMultipliers;
    }

    function stake(uint256 _lpAmount, uint8 _lockupIntervalIndex) external override {
        if (_lpAmount == 0) {
            revert LPAmountZero();
        }

        uint256 weight = getLpIntervalWeight(_lpAmount, _lockupIntervalIndex);
        updateRewardsPerWeight(weight, true);

        stakingToken.safeTransferFrom(msg.sender, address(this), _lpAmount);

        userStakes[msg.sender].push(
            UserStake({
                lpAmount: _lpAmount,
                checkpoint: rewardsPerWeight.accumulated,
                startedAt: block.timestamp.toUint32(),
                lockupIntervalIndex: _lockupIntervalIndex,
                claimed: false,
                forfeited: false
            })
        );

        emit LpTokensStaked(
            msg.sender,
            (userStakes[msg.sender].length - 1).toUint16(),
            _lpAmount,
            lockupIntervals[_lockupIntervalIndex]
        );
    }

    function unstakeClaim(uint16 _userStakeIndex) external override {
        UserStake storage userStake = userStakes[msg.sender][_userStakeIndex];

        if (block.timestamp < userStake.startedAt + lockupIntervals[userStake.lockupIntervalIndex]) {
            revert LockupTimeUnmet();
        }

        uint256 reward = getUserStakeReward(msg.sender, _userStakeIndex);

        rewardsToken.safeTransfer(msg.sender, reward);

        unstake(_userStakeIndex, true);
        emit LpTokensUnstaked(msg.sender, _userStakeIndex, userStake.lpAmount, reward);
    }

    function unstakeForfeit(uint16 _userStakeIndex) external override {
        unstake(_userStakeIndex, false);
        emit LpTokensUnstakeForfeited(msg.sender, _userStakeIndex, userStakes[msg.sender][_userStakeIndex].lpAmount);
    }

    function setRewards(uint32 _start, uint32 _end, uint96 _rate) external onlyOwner {
        if (rewardsSet) {
          revert RewardsAlreadySet();
        }

        if (rewardsPerWeight.totalWeight == 0) {
          revert StakedPositionsRequired();
        }

        if (block.timestamp > _start || block.timestamp + 30 days < _start) {
          revert InvalidStart();
        }

        if (_start >= _end) {
            revert InvalidStartEnd();
        }
        if (_rate < 1 ether) {
            revert InvalidRewardRate();
        }

        rewardsPeriod.start = _start;
        rewardsPeriod.end = _end;

        rewardsPerWeight.lastUpdated = _start;
        rewardsPerWeight.rate = _rate;

        rewardsSet = true;

        emit RewardsSet(_start, _end, _rate);
    }

    function estimateStakeReward(
        uint256 _lpAmount,
        uint8 _lockupIntervalIndex
    ) external view override returns (uint256) {
        // the assumed estimate if weight were not to change the duration of the staking, used for initial stake estimate.
        uint32 duration = lockupIntervals[_lockupIntervalIndex];
        uint256 stakeWeight = getLpIntervalWeight(_lpAmount, _lockupIntervalIndex);

        return duration * rewardsPerWeight.rate * stakeWeight / (rewardsPerWeight.totalWeight + stakeWeight);
    }

    function getUserStakeReward(address _user, uint16 _userStakeIndex) public view override returns (uint256) {
        RewardsPerWeight memory rewardsPerWeight_ = rewardsPerWeight;
        UserStake storage userStake = userStakes[_user][_userStakeIndex];

        if (userStake.claimed || userStake.forfeited) {
            return 0;
        }

        // Find out the unaccounted time
        // End is the lowest of current timestamp, reward period end, or lockup end time.
        uint32 end = min(block.timestamp.toUint32(), rewardsPeriod.end);

        uint256 unaccountedTime = end - rewardsPerWeight_.lastUpdated; // Cast to uint256 to avoid overflows later on
        if (unaccountedTime != 0) {
            // Calculate and update the new value of the accumulator. unaccountedTime casts it into uint256, which is desired.
            if (rewardsPerWeight_.totalWeight != 0) {
                rewardsPerWeight_.accumulated = (rewardsPerWeight_.accumulated +
                    (unaccountedTime * rewardsPerWeight_.rate) /
                    rewardsPerWeight_.totalWeight).toUint96();
            }
        }

        // Calculate and update the new value user reserves. userRewards_.stakedWeight casts it into uint256, which is desired.
        return getUserStakeWeight(userStake) * (rewardsPerWeight_.accumulated - userStake.checkpoint);
    }

    function getUserStakeRewards(
        address _user,
        uint16[] calldata _userStakeIndexes
    ) external view override returns (uint256[] memory) {
        uint256[] memory stakeRewards = new uint256[](_userStakeIndexes.length);

        for (uint256 i = 0; i < _userStakeIndexes.length; i++) {
            stakeRewards[i] = getUserStakeReward(_user, _userStakeIndexes[i]);
        }

        return stakeRewards;
    }

    function getUserStake(address _user, uint16 _userStakeIndex) external view override returns (UserStake memory) {
        return userStakes[_user][_userStakeIndex];
    }

    function getUserStakes(address _user) external view override returns (UserStake[] memory) {
        return userStakes[_user];
    }

    function getUserStakesCount(address _user) external view override returns (uint256) {
        return userStakes[_user].length;
    }

    function getLockupIntervals() external view override returns (uint32[] memory) {
        return lockupIntervals;
    }

    function getLockupIntervalsCount() external view override returns (uint8) {
        return lockupIntervals.length.toUint8();
    }

    function getLockupIntervalMultipliers() external view override returns (uint8[] memory) {
        return lockupIntervalMultipliers;
    }

    function unstake(uint16 _userStakeIndex, bool _claimed) internal {
        UserStake storage userStake = userStakes[msg.sender][_userStakeIndex];
        if (userStake.claimed || userStake.forfeited) {
            revert AlreadyUnstaked();
        }

        updateRewardsPerWeight(getUserStakeWeight(userStake), false);

        userStake.claimed = _claimed;
        userStake.forfeited = !_claimed;

        stakingToken.safeTransfer(msg.sender, userStake.lpAmount);
    }

    function updateRewardsPerWeight(uint256 _weight, bool _increase) internal {
        if (block.timestamp.toUint32() >= rewardsPeriod.start) {
            uint32 end = min(block.timestamp.toUint32(), rewardsPeriod.end);
            uint256 unaccountedTime = end - rewardsPerWeight.lastUpdated;

            if (unaccountedTime != 0) {
                if (rewardsPerWeight.totalWeight != 0) {
                    rewardsPerWeight.accumulated = (rewardsPerWeight.accumulated +
                        (unaccountedTime * rewardsPerWeight.rate) /
                        rewardsPerWeight.totalWeight).toUint96();
                }

                rewardsPerWeight.lastUpdated = end;
            }
        }

        if (_increase) {
            rewardsPerWeight.totalWeight += _weight;
        } else {
            rewardsPerWeight.totalWeight -= _weight;
        }

        emit RewardsPerWeightUpdated(rewardsPerWeight.accumulated);
    }

    function getLpIntervalWeight(uint256 _lpAmount, uint8 _lockupIntervalIndex) internal view returns (uint256 weight) {
        weight = _lpAmount * lockupIntervalMultipliers[_lockupIntervalIndex];
    }

    function getUserStakeWeight(UserStake memory _userStake) internal view returns (uint256 weight) {
        weight = getLpIntervalWeight(_userStake.lpAmount, _userStake.lockupIntervalIndex);
    }

    function min(uint32 _x, uint32 _y) internal pure returns (uint32 z) {
        z = (_x < _y) ? _x : _y;
    }
}