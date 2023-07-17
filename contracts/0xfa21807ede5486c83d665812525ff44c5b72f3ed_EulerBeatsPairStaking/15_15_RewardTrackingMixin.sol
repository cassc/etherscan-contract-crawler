// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @dev Adds fractional reward tracking.  Each share is equally weighted.  This is generic in that
 * it can track anything -- it's not tied to a staked token or ether as the reward (rewards can be ether, ERC20, ...),
 * and this book-keeping should be done outside this contract.
 */
abstract contract RewardTrackingMixin {
    struct AccountInfo {
        uint256 shares;
        uint256 rewardDebt;
    }

    // total number of shares deposited
    uint256 public totalShares;

    // always increasing value
    uint256 private accumulatedRewardPerShare;

    mapping(address => AccountInfo) private accountRewards;

    function _addReward(uint256 amount) internal {
        if (totalShares == 0 || amount == 0) {
            return;
        }

        uint256 rewardPerShare = amount / totalShares;
        accumulatedRewardPerShare += rewardPerShare;
    }

    /**
     * @dev Updates the amount of shares for a user.  Callers must keep track of the share count
     * for a particular user to reduce storage required.
     */
    function _addShares(address account, uint256 amount) internal {
        totalShares += amount;

        accountRewards[account].shares += amount;
        _updateRewardDebtToCurrent(account);
    }

    function _removeShares(address account, uint256 amount) internal {
        require(amount <= accountRewards[account].shares, "Invalid account amount");
        require(amount <= totalShares, "Invalid global amount");

        totalShares -= amount;

        accountRewards[account].shares -= amount;
        _updateRewardDebtToCurrent(account);
    }

    /**
     * @dev Resets the given account to the initial state.  This should be used with caution!
     */
    function _resetRewardAccount(address account) internal {
        uint256 currentShares = accountRewards[account].shares;
        if (currentShares > 0) {
            totalShares -= currentShares;
            accountRewards[account].shares = 0;
            accountRewards[account].rewardDebt = 0;
        }
    }

    function _updateRewardDebtToCurrent(address account) internal {
        accountRewards[account].rewardDebt = accountRewards[account].shares * accumulatedRewardPerShare;
    }

    function accountPendingReward(address account) public view returns (uint256 pendingReward) {
        return accountRewards[account].shares * accumulatedRewardPerShare - accountRewards[account].rewardDebt;
    }

    function accountRewardShares(address account) public view returns (uint256 rewardShares) {
        return accountRewards[account].shares;
    }
}