// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @notice
 * VEWFire holders can claim usdc on this contract
 */

contract RewardDistributor is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount; // amount of veWFIRE by the user
        uint256 rewardDebt; // amount to be cut off in rewards calculation - updated when deposit, withdraw or claim
        uint256 pendingRewards; // pending rewards for the user
    }

    struct PoolInfo {
        uint256 accTokenPerShare; // accumulative rewards per deposited token
        uint256 totalAmount; // total veWFIRE amount
        uint256 rewardsAmount; // total rewards amount of the contract - change on rewards distribution / claim
    }

    uint256 public constant SHARE_MULTIPLIER = 1e20;

    IERC20 public token;
    IERC20 public vewFIRE;

    uint256 public totalDistributed;
    uint256 public totalReleased;

    PoolInfo public poolInfo;
    mapping(address => UserInfo) public userInfo;

    event Update(address indexed user, uint256 newBalance);
    event Claim(address indexed user, uint256 amount);

    constructor(IERC20 _token, IERC20 _vewFIRE) {
        token = _token;
        vewFIRE = _vewFIRE;
    }

    function updateFactor(address userAddr, uint256 newBalance) external {
        require(msg.sender == address(vewFIRE), "Invalid");
        if (newBalance == 0) {
            return;
        }

        uint256 amount = sqrt(newBalance);

        _updatePool();
        _updateUserPendingRewards(userAddr);

        UserInfo storage user = userInfo[userAddr];

        poolInfo.totalAmount = poolInfo.totalAmount + amount - user.amount;
        user.amount = amount;

        user.rewardDebt = accumulativeRewards(user.amount, poolInfo.accTokenPerShare);

        emit Update(userAddr, amount);
    }

    function getTotalDistributableRewards() public view returns (uint256) {
        return token.balanceOf(address(this)) + totalReleased - totalDistributed;
    }

    function accumulativeRewards(
        uint256 amount,
        uint256 _accTokenPerShare
    ) internal pure returns (uint256) {
        return (amount * _accTokenPerShare) / (SHARE_MULTIPLIER);
    }

    /**
     * @notice get pending rewards of a user
     *
     * @param _user: User Address
     */
    function pendingRewards(address _user) external view returns (uint256) {
        require(_user != address(0), "Invalid user address");
        UserInfo storage user = userInfo[_user];
        uint256 accTokenPerShare = poolInfo.accTokenPerShare;
        uint256 totalAmount = poolInfo.totalAmount;

        uint256 tokenReward = getTotalDistributableRewards();

        if (tokenReward != 0 && totalAmount != 0) {
            accTokenPerShare += (tokenReward * SHARE_MULTIPLIER) / totalAmount;
        }

        // last_accumulated_reward is expressed as rewardDebt
        // accumulated_rewards - last_accumulated_reward + last_pending_rewards
        return
            accumulativeRewards(user.amount, accTokenPerShare) -
            user.rewardDebt +
            user.pendingRewards;
    }

    /**
     * @notice claim rewards
     *
     */
    function claim() external nonReentrant {
        _updatePool();
        _updateUserPendingRewards(msg.sender);
        processRewards(msg.sender);

        UserInfo storage user = userInfo[msg.sender];

        user.rewardDebt = accumulativeRewards(user.amount, poolInfo.accTokenPerShare);
    }

    /**
     * @notice _updatePool distribute pendingRewards
     *
     */
    function _updatePool() internal {
        if (poolInfo.totalAmount == 0) {
            return;
        }
        uint256 tokenReward = getTotalDistributableRewards();
        poolInfo.rewardsAmount += tokenReward;
        // accTokenPerShare is by definition accumulation of token rewards per delegated token
        poolInfo.accTokenPerShare += (tokenReward * SHARE_MULTIPLIER) / poolInfo.totalAmount;

        totalDistributed += tokenReward;
    }

    function _updateUserPendingRewards(address addr) internal {
        UserInfo storage user = userInfo[addr];
        if (user.amount == 0) {
            return;
        }

        user.pendingRewards +=
            accumulativeRewards(user.amount, poolInfo.accTokenPerShare) -
            user.rewardDebt;
    }

    function processRewards(address addr) private {
        UserInfo storage user = userInfo[addr];

        uint256 rewards = user.pendingRewards;
        uint256 claimedAmount = safeTokenTransfer(addr, rewards);

        totalReleased += claimedAmount;
        user.pendingRewards = user.pendingRewards - claimedAmount;
        poolInfo.rewardsAmount -= claimedAmount;

        emit Claim(addr, claimedAmount);
    }

    function safeTokenTransfer(address to, uint256 amount) internal returns (uint256) {
        if (amount > poolInfo.rewardsAmount) {
            token.safeTransfer(to, poolInfo.rewardsAmount);
            return poolInfo.rewardsAmount;
        } else {
            token.safeTransfer(to, amount);
            return amount;
        }
    }

    function withdrawAnyToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}