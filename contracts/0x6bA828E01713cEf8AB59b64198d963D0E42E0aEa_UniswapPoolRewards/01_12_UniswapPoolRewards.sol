// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IPoolRewards.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniswapPoolRewards is IPoolRewards, AccessControl {
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    IERC20 public poolToken;

    uint256 public rewardRatePerSecond = 0.125 * 1e18; // ~324,000 per month
    uint256 public lastRewardPerPoolToken;
    uint256 public lastUpdateTimestamp;

    mapping(address => uint256) public poolTokenBalances;
    mapping(address => uint256) public rewardBalances;
    mapping(address => uint256) public rewardPerPoolTokenClaimed;

    event PoolTokensDeposited(address indexed account, uint256 amount);
    event PoolTokensWithdrawn(address indexed account, uint256 amount);
    event RewardClaimed(address indexed account, uint256 amount);

    constructor(address rewardToken_, address poolToken_) {
        rewardToken = IERC20(rewardToken_);
        poolToken = IERC20(poolToken_);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setRewardRatePerSecond(uint256 rewardRatePerSecond_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateLastRewardPerPoolToken();
        rewardRatePerSecond = rewardRatePerSecond_;
    }

    function rewardPerPoolToken() public view returns (uint256) {
        uint256 poolTokenBalance = poolToken.balanceOf(address(this));
        if (poolTokenBalance == 0) {
            return lastRewardPerPoolToken;
        }
        return lastRewardPerPoolToken + ((block.timestamp - lastUpdateTimestamp) * rewardRatePerSecond * 1e18) / poolTokenBalance;
    }

    function claimableReward(address account) public view returns (uint256) {
        return rewardBalances[account] + (poolTokenBalances[account] * (rewardPerPoolToken() - rewardPerPoolTokenClaimed[account])) / 1e18;
    }

    function depositPoolTokens(uint256 amount) public {
        require(rewardRatePerSecond > 0, "This reward contract is not active");
        require(amount > 0, "Cannot deposit 0");

        _updateRewardBalances();

        poolToken.safeTransferFrom(msg.sender, address(this), amount);
        poolTokenBalances[msg.sender] = poolTokenBalances[msg.sender] + amount;
        emit PoolTokensDeposited(msg.sender, amount);
    }

    function withdrawPoolTokens() public {
        uint256 poolTokenBalance = poolTokenBalances[msg.sender];
        require(poolTokenBalance > 0, "Cannot withdraw 0");

        _updateRewardBalances();

        poolToken.safeTransfer(msg.sender, poolTokenBalance);
        poolTokenBalances[msg.sender] = 0;
        emit PoolTokensWithdrawn(msg.sender, poolTokenBalance);
    }

    function claimReward() public {
        _updateRewardBalances();

        uint256 reward = claimableReward(msg.sender);
        require(reward > 0, "Nothing to claim");

        rewardToken.safeTransfer(msg.sender, reward);
        rewardBalances[msg.sender] = 0;
        emit RewardClaimed(msg.sender, reward);
    }

    function withdrawPoolTokensAndClaimReward() public {
        withdrawPoolTokens();
        claimReward();
    }

    function _updateLastRewardPerPoolToken() internal {
        lastRewardPerPoolToken = rewardPerPoolToken();
        lastUpdateTimestamp = block.timestamp;
    }

    function _updateRewardBalances() internal {
        _updateLastRewardPerPoolToken();
        rewardBalances[msg.sender] = claimableReward(msg.sender);
        rewardPerPoolTokenClaimed[msg.sender] = lastRewardPerPoolToken;
    }
}