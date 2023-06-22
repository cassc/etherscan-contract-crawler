// SPDX-License-Identifier: GPL-2.0-or-later

// adapted from https://github.com/Synthetixio/synthetix/blob/c53070db9a93e5717ca7f74fcaf3922e991fb71b/contracts/StakingRewards.sol
pragma solidity ^0.8.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";

import {IReward} from "./interfaces/IReward.sol";
import {Math as MavMath} from "./libraries/Math.sol";
import {BitMap} from "./libraries/BitMap.sol";
import {IPoolPositionAndRewardFactorySlim} from "./interfaces/IPoolPositionAndRewardFactorySlim.sol";

abstract contract RewardBase is IReward, ReentrancyGuard, Multicall {
    using SafeERC20 for IERC20;
    using BitMap for BitMap.Instance;

    uint8 public MAX_REWARD_TOKENS = 16;
    uint256 constant ONE = 1e18;
    // after this period of time without a reward, users can remove token from
    // list
    uint256 constant STALE_INTERVAL = 30 days;

    IPoolPositionAndRewardFactorySlim public immutable rewardFactory;
    IERC20 public immutable stakingToken;

    // Max Duration of rewards to be paid out
    uint256 constant MAX_DURATION = 30 days;
    uint256 constant MIN_DURATION = 3 days;

    // Total staked
    uint256 public totalSupply;
    // User address => staked amount
    mapping(address => uint256) public balanceOf;

    struct RewardData {
        // Timestamp of when the rewards finish
        uint256 finishAt;
        // Minimum of last updated time and reward finish time
        uint256 updatedAt;
        // Reward to be paid out per second
        uint256 rewardRate;
        // Sum of (reward rate * dt * 1e18 / total supply)
        uint256 rewardPerTokenStored;
        // User address => rewardPerTokenStored
        mapping(address => uint256) userRewardPerTokenPaid;
        // User address => rewards to be claimed
        mapping(address => uint256) rewards;
        // User address => rewards mapping to track if token index has been
        // updated
        mapping(address => uint256) resetCount;
        // total earned
        uint256 escrowedReward;
        uint256 globalResetCount;
        IERC20 rewardToken;
    }
    RewardData[] public rewardData;
    mapping(address => uint8) public tokenIndex;

    BitMap.Instance public globalActive;

    constructor(IERC20 _stakingToken, IPoolPositionAndRewardFactorySlim _rewardFactory) {
        stakingToken = _stakingToken;

        rewardFactory = _rewardFactory;
        // push empty token so that we can use index zero as a sentinel value
        // in tokenIndex mapping; ie if tokenIndex[X] = 0, we know X is not in
        // the list
        rewardData.push();
    }

    modifier checkAmount(uint256 amount) {
        if (amount == 0) revert ZeroAmount();
        _;
    }

    /////////////////////////////////////
    /// View Functions
    /////////////////////////////////////

    function rewardInfo() external view returns (RewardInfo[] memory info) {
        uint256 length = rewardData.length;
        info = new RewardInfo[](length);
        for (uint8 i = 1; i < length; i++) {
            RewardData storage data = rewardData[i];
            info[i] = RewardInfo({finishAt: data.finishAt, updatedAt: data.updatedAt, rewardRate: data.rewardRate, rewardPerTokenStored: data.rewardPerTokenStored, rewardToken: data.rewardToken});
        }
    }

    function earned(address account) public view returns (EarnedInfo[] memory earnedInfo) {
        uint256 length = rewardData.length;
        earnedInfo = new EarnedInfo[](length);
        for (uint8 i = 1; i < length; i++) {
            RewardData storage data = rewardData[i];
            earnedInfo[i] = EarnedInfo({account: account, earned: earned(account, data), rewardToken: data.rewardToken});
        }
    }

    function earned(address account, address rewardTokenAddress) external view returns (uint256) {
        uint256 rewardTokenIndex = tokenIndex[rewardTokenAddress];
        if (rewardTokenIndex == 0) revert NotValidRewardToken(rewardTokenAddress);
        RewardData storage data = rewardData[rewardTokenIndex];
        return earned(account, data);
    }

    function earned(address account, RewardData storage data) internal view returns (uint256) {
        return data.rewards[account] + Math.mulDiv(balanceOf[account], MavMath.clip(data.rewardPerTokenStored + deltaRewardPerToken(data), data.userRewardPerTokenPaid[account]), ONE);
    }

    /////////////////////////////////////
    /// Internal Update Functions
    /////////////////////////////////////

    function updateReward(address account, RewardData storage data) internal {
        uint256 reward = deltaRewardPerToken(data);
        if (reward != 0) {
            data.rewardPerTokenStored += reward;
            data.escrowedReward += Math.mulDiv(reward, totalSupply, ONE, Math.Rounding(1));
        }
        data.updatedAt = lastTimeRewardApplicable(data.finishAt);

        if (account != address(0)) {
            if (data.resetCount[account] != data.globalResetCount) {
                // check to see if this token index was changed
                data.userRewardPerTokenPaid[account] = 0;
                data.rewards[account] = 0;
                data.resetCount[account] = data.globalResetCount;
            }
            data.rewards[account] += deltaEarned(account, data);
            data.userRewardPerTokenPaid[account] = data.rewardPerTokenStored;
        }
    }

    function deltaEarned(address account, RewardData storage data) internal view returns (uint256) {
        return Math.mulDiv(balanceOf[account], MavMath.clip(data.rewardPerTokenStored, data.userRewardPerTokenPaid[account]), ONE);
    }

    function deltaRewardPerToken(RewardData storage data) internal view returns (uint256) {
        uint256 timeDiff = MavMath.clip(lastTimeRewardApplicable(data.finishAt), data.updatedAt);
        if (timeDiff == 0 || totalSupply == 0 || data.rewardRate == 0) {
            return 0;
        }
        return Math.mulDiv(data.rewardRate, timeDiff * ONE, totalSupply);
    }

    function lastTimeRewardApplicable(uint256 dataFinishAt) internal view returns (uint256) {
        return Math.min(dataFinishAt, block.timestamp);
    }

    function updateAllRewards(address account) internal {
        uint256 length = rewardData.length;
        for (uint8 i = 1; i < length; i++) {
            if (!globalActive.get(i)) continue;

            RewardData storage data = rewardData[i];

            updateReward(account, data);
        }
    }

    /// @dev add token if it is approved and is not already tracked
    function _checkAndAddRewardToken(address rewardTokenAddress) internal returns (uint8 rewardTokenIndex) {
        rewardTokenIndex = tokenIndex[rewardTokenAddress];
        if (rewardTokenIndex != 0) return rewardTokenIndex;

        if (!rewardFactory.isApprovedRewardToken(rewardTokenAddress)) revert NotValidRewardToken(rewardTokenAddress);

        // find first unset token index and use it
        for (uint8 i = 1; i < MAX_REWARD_TOKENS + 1; i++) {
            if (globalActive.get(i)) continue;
            rewardTokenIndex = i;
            break;
        }
        if (rewardTokenIndex == 0) revert TooManyRewardTokens();
        if (rewardTokenIndex == rewardData.length) rewardData.push();

        RewardData storage _data = rewardData[rewardTokenIndex];

        _data.rewardToken = IERC20(rewardTokenAddress);
        _data.globalResetCount++;

        tokenIndex[rewardTokenAddress] = rewardTokenIndex;
        globalActive.set(rewardTokenIndex);
        emit AddRewardToken(rewardTokenAddress, rewardTokenIndex);
    }

    /////////////////////////////////////
    /// Internal User Functions
    /////////////////////////////////////

    function _stake(address supplier, uint256 amount, address account) internal nonReentrant checkAmount(amount) {
        updateAllRewards(account);
        stakingToken.safeTransferFrom(supplier, address(this), amount);
        balanceOf[account] += amount;
        totalSupply += amount;
        emit Stake(msg.sender, supplier, amount, account, balanceOf[account], totalSupply);
    }

    function _unstake(address account, uint256 amount, address recipient) internal nonReentrant checkAmount(amount) {
        updateAllRewards(account);
        balanceOf[account] -= amount;
        totalSupply -= amount;
        stakingToken.safeTransfer(recipient, amount);
        emit UnStake(msg.sender, account, amount, recipient, balanceOf[account], totalSupply);
    }

    function _unstakeAll(address account, address recipient) internal {
        _unstake(account, balanceOf[account], recipient);
    }

    function _getReward(address account, address recipient, uint8 rewardTokenIndex) internal nonReentrant returns (uint256 reward) {
        if (!globalActive.get(rewardTokenIndex)) revert StaleToken(rewardTokenIndex);
        RewardData storage data = rewardData[rewardTokenIndex];
        updateReward(account, data);
        reward = data.rewards[account];
        if (reward != 0) {
            data.rewards[account] = 0;
            data.escrowedReward -= reward;
            data.rewardToken.safeTransfer(recipient, reward);
        }
        emit GetReward(msg.sender, account, recipient, rewardTokenIndex, address(data.rewardToken), reward);
    }

    function _getReward(address account, address recipient, uint8[] memory rewardTokenIndices) internal {
        uint256 length = rewardTokenIndices.length;
        for (uint8 i; i < length; i++) {
            _getReward(account, recipient, rewardTokenIndices[i]);
        }
    }

    /////////////////////////////////////
    /// Add Reward
    /////////////////////////////////////

    /// @notice Adds reward to contract.
    function notifyAndTransfer(address rewardTokenAddress, uint256 amount, uint256 duration) public nonReentrant {
        if (duration < MIN_DURATION) revert DurationOutOfBounds(duration);

        uint256 minimumAmount = rewardFactory.minimumRewardAmount(rewardTokenAddress);
        if (amount < minimumAmount) revert RewardAmountBelowThreshold(amount, minimumAmount);

        duration = _notifyRewardAmount(rewardTokenAddress, amount, duration);

        if (duration > MAX_DURATION) revert DurationOutOfBounds(duration);
        IERC20(rewardTokenAddress).safeTransferFrom(msg.sender, address(this), amount);
    }

    /* @notice called by reward depositor to recompute the reward rate.  If
     *  notifier sends more than remaining amount, then notifier sets the rate.
     *  Else, we extend the duration at the current rate. We may notify with less
     *  than enough of assets to cover the period. In that case, reward rate will
     *  be 0 and the assets sit on the contract until another notify happens with
     *  enough assets for a positive rate.
     *   @dev Must notify before transfering assets.  Transfering and then
     *  notifying with the same amount will break the logic of this reward
     *  contract.  If a contract needs to transfer and then notify, the
     *  notification amount should be 0.
     */
    function _notifyRewardAmount(address rewardTokenAddress, uint256 amount, uint256 duration) internal returns (uint256) {
        uint8 rewardTokenIndex = _checkAndAddRewardToken(rewardTokenAddress);
        RewardData storage data = rewardData[rewardTokenIndex];
        updateReward(address(0), data);
        uint256 remainingRewards = MavMath.clip(data.rewardToken.balanceOf(address(this)), data.escrowedReward);

        if (amount > remainingRewards || data.rewardRate == 0) {
            // if notifying new amount, notifier gets to set the rate
            data.rewardRate = (amount + remainingRewards) / duration;
        } else {
            // if notifier doesn't bring enough, we extend the duration at the
            // same rate
            duration = (amount + remainingRewards) / data.rewardRate;
        }

        data.finishAt = block.timestamp + duration;
        data.updatedAt = block.timestamp;
        emit NotifyRewardAmount(msg.sender, rewardTokenAddress, amount, duration, data.rewardRate);
        return duration;
    }

    /////////////////////////////////////
    /// Admin Function
    /////////////////////////////////////

    function removeStaleToken(uint8 rewardTokenIndex) public virtual nonReentrant {
        _removeStaleToken(rewardTokenIndex);
    }

    function _removeStaleToken(uint8 rewardTokenIndex) internal {
        RewardData storage data = rewardData[rewardTokenIndex];
        if (block.timestamp < STALE_INTERVAL + data.finishAt) revert TokenNotStale(rewardTokenIndex);
        emit RemoveRewardToken(address(data.rewardToken), rewardTokenIndex);

        // remove token from list
        globalActive.unset(rewardTokenIndex);
        delete tokenIndex[address(data.rewardToken)];

        delete data.rewardToken;
        delete data.escrowedReward;
        delete data.rewardPerTokenStored;
        delete data.rewardRate;
        delete data.finishAt;
        delete data.updatedAt;
    }
}