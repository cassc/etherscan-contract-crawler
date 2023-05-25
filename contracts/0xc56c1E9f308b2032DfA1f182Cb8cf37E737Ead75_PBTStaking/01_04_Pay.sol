// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * This contract should only be used to stake PBT token, and earn PBT token rewards.
 */
contract PBTStaking is Ownable {

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    uint256 lastRewardBlock; // Last block number that PBTs distribution occurs.
    uint256 accPbtPerShare; // Accumulated PBTs per share, times 1e12.

    // The PBT TOKEN
    IERC20 public immutable pbt;
    // PBT tokens minted per block.
    uint256 public pbtPerBlock;
    // The source of all PBT rewards
    uint256 public pbtForRewards;
    // The total PBT deposits
    uint256 public totalDeposits;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(IERC20 _pbt, uint256 _pbtPerBlock, uint256 _startBlock) {
        require(_startBlock > block.number, "StartBlock must be in the future");
        pbt = _pbt;
        pbtPerBlock = _pbtPerBlock;
        lastRewardBlock = _startBlock;
    }

    // View function to see pending PBT rewards on frontend.
    function pendingPbt(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];

        uint256 rewardPerShare = accPbtPerShare;
        uint256 denominator = totalDeposits;
        if (block.number > lastRewardBlock && denominator != 0) {
            uint256 pbtReward = (block.number - lastRewardBlock) * pbtPerBlock;
            rewardPerShare += (pbtReward * 1e12 / denominator);
        }
        return (user.amount * rewardPerShare / 1e12) - user.rewardDebt;
    }

    // Admin function to update PBT per block reward
    function setPbtPerBlock(uint256 newValue) external onlyOwner() {
        _updateRewards();
        pbtPerBlock = newValue;
    }

    // Deposit PBT tokens
    function deposit(uint256 _amount) external {
        _deposit(_amount);
    }

    // Compound reward PBT tokens
    function compoundDeposit() external {
        _deposit(0);
    }

    // Withdraw PBT tokens (deposit + rewards)
    function withdraw(uint256 _amount) external {
        _withdraw(_amount);
    }

    // Withdraw PBT tokens (only rewards)
    function claimRewards() external {
        _withdraw(0);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        pbt.transfer(address(msg.sender), user.amount);

        user.amount = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    function _deposit(uint256 _amount) internal {
        _updateRewards();

        UserInfo storage user = userInfo[msg.sender];

        uint256 pending;
        if (user.amount > 0) {
            pending = (user.amount * accPbtPerShare / 1e12) - user.rewardDebt;
        }
        user.amount += _amount + pending;
        user.rewardDebt = user.amount * accPbtPerShare / 1e12;

        totalDeposits += _amount + pending;

        if(_amount > 0) {
            pbt.transferFrom(address(msg.sender), address(this), _amount);
        }
        emit Deposit(msg.sender, _amount);
    }

    function _withdraw(uint256 _amount) internal {
        _updateRewards();

        UserInfo storage user = userInfo[msg.sender];
        uint256 pending = (user.amount * accPbtPerShare / 1e12) - user.rewardDebt;

        require(_amount <= user.amount + pending, "Withdrawal exceeds balance");

        user.amount -= _amount;
        user.rewardDebt = user.amount * accPbtPerShare / 1e12;

        totalDeposits -= _amount;

        pbt.transfer(address(msg.sender), _amount + pending);
        emit Withdraw(msg.sender, _amount + pending);
    }

    // Update rewards
    function _updateRewards() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 denominator = totalDeposits;
        if (denominator == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 pbtReward = (block.number - lastRewardBlock) * pbtPerBlock;
        require(pbt.balanceOf(address(this)) - pbtForRewards - totalDeposits >= pbtReward, "Insufficient PBT tokens for rewards");
        pbtForRewards += pbtReward;
        accPbtPerShare += (pbtReward * 1e12 / denominator);
        lastRewardBlock = block.number;
    }
}