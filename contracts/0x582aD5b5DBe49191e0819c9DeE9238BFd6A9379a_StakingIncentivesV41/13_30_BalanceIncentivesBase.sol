//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../lib/Utils.sol";
import "../upgrade/FsBase.sol";

/// @title Balance incentives reward a balance over a period of time.
/// Balances for accounts are updated by the balanceUpdater by calling changeBalance.
/// Accounts can claim tokens by calling claim
abstract contract BalanceIncentivesBase is FsBase {
    using SafeERC20 for IERC20;

    /// @notice A sum of all user balances, as stored in the `balances` mapping.
    uint256 public totalBalance;
    /// @notice Balances of individual users.
    mapping(address => uint256) balances;

    /// @notice Rewards already allocated to individual users, but not claimed by the users.
    ///
    ///         We update rewards only inside the `update()` call and only for one single account.
    ///         So this mapping does not reflect the total amount of rewards an account has
    ///         accumulated.
    ///
    ///         It is the amount of rewards allocated to an account at the last point in time when
    ///         this account interacted with the contract: either the account balance was modified,
    ///         or the account claimed their rewards.
    mapping(address => uint256) rewards;

    /// @notice Part of `cumulativeRewardPerBalance` that has been already added to the
    ///         `rewards` field, for a particular user.
    ///
    ///         Difference between `cumulativeRewardPerBalance` and `rewards[<account>]` represents
    ///         rewards that the user is already entitled to.  `rewards[<account>]` has not been
    ///         updated with this portion as the user did not interact with the system since then.
    mapping(address => uint256) userRewardPerBalancePaid;

    /// @notice The rate of rewards per time unit
    uint256 public rewardRate;
    /// @notice The cumulative reward per balance
    uint256 public cumulativeRewardPerBalance;

    /// @notice Timestamp of the last update of the `cumulativeRewardPerBalance`.
    uint256 public lastUpdated;
    /// @notice Timestamp of the reward period end
    uint256 public rewardPeriodFinish;

    /// @notice The address of the rewards token
    IERC20 public rewardsToken;

    function initializeBalanceIncentivesBase(address _rewardsToken) internal initializer {
        rewardsToken = IERC20(nonNull(_rewardsToken));
        initializeFsOwnable();
    }

    /// @notice Updates the balance of an account
    /// @param account the account to update
    /// @param balance the new balance of the account
    function changeBalance(address account, uint256 balance) internal {
        emit ChangeBalance(account, balances[account], balance);

        update(account);

        uint256 previous = balances[account];
        balances[account] = balance;

        totalBalance += balance;
        totalBalance -= previous;
    }

    /// @notice Claim rewards for a given user.  Derived contracts may override `sendTokens`
    ///         function, changing what exactly happens to the claimed tokens.
    /// @param account The account to claim for
    /// @param lockupTime The lockup period (see subclasses)
    function doClaim(address account, uint256 lockupTime) internal {
        update(account);
        uint256 reward = rewards[account];
        if (reward > 0) {
            rewards[account] = 0;
            sendTokens(account, reward, lockupTime);
            emit Claim(account, reward);
        }
    }

    /// @notice Customization point for the token claim process.  Allows derived contracts to define
    ///         what happens to the claimed tokens.  `LockBalanceIncentives` locks tokens, instead
    ///         of sending them to the user right away.
    ///
    ///         Default implementation just sends the tokens to the specified `account`.
    ///
    /// @param account The account to send tokens to.
    /// @param amount Amount of tokens that were claimed.
    function sendTokens(
        address account,
        uint256 amount,
        uint256
    ) internal virtual {
        rewardsToken.safeTransfer(account, amount);
    }

    /// @notice Returns the amount of reward token per balance unit
    function rewardPerBalance() external view returns (uint256) {
        return cumulativeRewardPerBalance + deltaRewardPerToken();
    }

    /// @notice Returns the amount of tokens that the account can claim
    /// @param _account The account to claim for
    function getClaimableTokens(address _account) external view returns (uint256) {
        return rewards[_account] + getDeltaClaimableTokens(_account, deltaRewardPerToken());
    }

    /// @notice Add rewards to the contract
    /// @param _reward The amount of tokens being added as a reward
    /// @param _rewardsDuration The time in seconds till the reward period ends
    function addRewards(uint256 _reward, uint256 _rewardsDuration) external onlyOwner {
        require(getTime() >= rewardPeriodFinish, "current period has not ended");
        extendRewardsUntil(_reward, getTime() + _rewardsDuration);
    }

    /// @notice Add rewards to the contract
    /// @param _reward The amount of tokens being added as a reward
    /// @param _newRewardPeriodfinish The time in unix time when the new reward period ends
    function extendRewardsUntil(uint256 _reward, uint256 _newRewardPeriodfinish) public onlyOwner {
        update(address(0));

        require(_newRewardPeriodfinish >= rewardPeriodFinish, "Can only extend not shorten period");
        if (getTime() < rewardPeriodFinish) {
            // Terminate the current rewards and add the unspent rewards to the the
            // new rewards. The algorithm suffers from rounding errors, however this is the best
            // approximation to the rewards left and because division rounds down will not
            // add to many rewards.
            _reward += (rewardPeriodFinish - getTime()) * rewardRate;
        }

        uint256 rewardsDuration = _newRewardPeriodfinish - getTime();
        rewardRate = _reward / rewardsDuration;

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        // Note this will not guard against the caller not providing enough reward tokens overall.
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance / rewardsDuration, "Provided reward too high");

        lastUpdated = getTime();
        rewardPeriodFinish = _newRewardPeriodfinish;

        emit AddRewards(rewardRate, balance, lastUpdated, rewardPeriodFinish);
    }

    /// @notice Update the rewards peroid to end earlier
    /// @param _timestamp The new timestamp on which to end the rewards period
    function updatePeriodFinish(uint256 _timestamp) external onlyOwner {
        update(address(0));
        require(_timestamp <= rewardPeriodFinish, "Can not extend");
        emit UpdatePeriodFinish(_timestamp);
        rewardPeriodFinish = _timestamp;
    }

    function deltaRewardPerToken() private view returns (uint256) {
        if (totalBalance == 0) {
            return 0;
        }

        uint256 maxTime = Math.min(getTime(), rewardPeriodFinish);
        uint256 deltaTime = maxTime - lastUpdated;
        return (deltaTime * rewardRate * 1 ether) / totalBalance;
    }

    function getDeltaClaimableTokens(address account, uint256 _deltaRewardPerToken)
        private
        view
        returns (uint256)
    {
        uint256 userDelta =
            cumulativeRewardPerBalance + _deltaRewardPerToken - userRewardPerBalancePaid[account];

        return (balances[account] * userDelta) / 1 ether;
    }

    function update(address account) private {
        uint256 calculatedDeltaRewardPerToken = deltaRewardPerToken();
        uint256 deltaTokensEarned = getDeltaClaimableTokens(account, calculatedDeltaRewardPerToken);

        cumulativeRewardPerBalance += calculatedDeltaRewardPerToken;
        lastUpdated = Math.min(getTime(), rewardPeriodFinish);

        if (account != address(0)) {
            rewards[account] += deltaTokensEarned;
            userRewardPerBalancePaid[account] = cumulativeRewardPerBalance;
        }
    }

    function setRewardsToken(address newRewardsToken) external onlyOwner {
        if (newRewardsToken == address(rewardsToken)) {
            return;
        }
        address oldRewardsToken = address(rewardsToken);
        rewardsToken = IERC20(FsUtils.nonNull(newRewardsToken));
        emit RewardsTokenUpdated(oldRewardsToken, newRewardsToken);
    }

    // Only present for unit tests
    function getTime() public view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @notice Emmited when a user claims their rewards token
    /// @param user The user claiming the tokens
    /// @param amount The amount of tokens being claimed
    event Claim(address indexed user, uint256 amount);

    /// @notice Emitted when new rewards are added to the contract
    /// @param rewardRate The new reward rate
    /// @param balance The current balance of reward tokens of the contract
    /// @param lastUpdated The last update of the cumulativeRewardPerBalance
    /// @param rewardPeriodFinish The timestamp on which the newly added period will end
    event AddRewards(
        uint256 rewardRate,
        uint256 balance,
        uint256 lastUpdated,
        uint256 rewardPeriodFinish
    );

    /// @notice Emitted if the end of a reward period is changed
    /// @param timestamp The new timestamp of the period end
    event UpdatePeriodFinish(uint256 timestamp);

    /// @notice Emitted when a balance of an account changes
    /// @param account The account balance being updated
    /// @param oldBalance The old balance of the account
    /// @param newBalance The new balance of the account
    event ChangeBalance(address indexed account, uint256 oldBalance, uint256 newBalance);

    /// @notice Event emitted the rewards token is updated.
    /// @param oldRewardsToken The rewards token before the update.
    /// @param newRewardsToken The rewards token after the update.
    event RewardsTokenUpdated(address oldRewardsToken, address newRewardsToken);
}