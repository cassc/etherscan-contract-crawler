// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "../dependencies/openzeppelin/contracts/IERC20Capped.sol";

interface IPhiatFeeDistribution {
    /* ========== STATE VARIABLES ========== */

    struct TokenReward {
        // updated via _getReward <- getReward
        uint256 periodFinish;
        // updated via _getReward <- getReward
        // every second how many rewards are accumulated for 1 wei
        // should divide by REWARD_RATE_PRECISION_ASSIST to get true reward rate
        uint256 rewardRate;
        // updated via _updateReward / _getReward <- stake / withdraw / getReward
        uint256 lastUpdateTime;
        // how much rewards have been accumulated so far
        // should divide by REWARD_RATE_PRECISION_ASSIST to get true reward
        // updated via _updateReward <- stake / withdraw / getReward
        uint256 rewardStored;
        // tracks already-added balances to handle accrued interest in phToken rewards
        // updated via _getReward <- getReward
        uint256 balance;
    }
    struct TimedBalance {
        uint256 amount;
        uint256 time; // when user can withdraw or unstaking expires
    }
    struct RewardAmount {
        address token;
        uint256 amount;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event UnstakeCancelled(address indexed user);
    event Withdrawn(address indexed user, uint256 receivedAmount);
    event RewardPaid(
        address indexed user,
        address indexed rewardToken,
        uint256 reward
    );

    function stakingToken() external view returns (IERC20Capped);

    function stakingTokenPrecision() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalStakedSupply() external view returns (uint256);

    function REWARD_DURATION() external view returns (uint256);

    function UNSTAKE_DURATION() external view returns (uint256);

    function WITHDRAW_DURATION() external view returns (uint256);

    function REWARD_RATE_PRECISION_ASSIST() external view returns (uint256);

    /* ========== REWARD VIEWS ========== */

    function lastTimeRewardApplicable(address tokenAddress)
        external
        view
        returns (uint256);

    // should divide by REWARD_RATE_PRECISION_ASSIST to get true reward per token
    // token's decimals are kept
    // staking token's decimals are removed
    function rewardPerToken(address tokenAddress)
        external
        view
        returns (uint256);

    function getRewardForDuration(address tokenAddress)
        external
        view
        returns (uint256);

    // Address and claimable amount of all reward tokens for the given account
    function claimableRewards(address account)
        external
        view
        returns (RewardAmount[] memory rewards);

    /* ========== STAKING VIEWS ========== */

    // Total staked balance of an account, including unstaked tokens that haven't been withdrawn
    function stakedBalance(address user) external view returns (uint256 amount);

    // Total unstaked balance for an account (in the process of unstaking)
    function unstakedBalance(address user)
        external
        view
        returns (TimedBalance memory balance);

    // Total withdrawable balance for an account
    function withdrawableBalance(address user)
        external
        view
        returns (TimedBalance memory balance);

    function getReward() external;
}