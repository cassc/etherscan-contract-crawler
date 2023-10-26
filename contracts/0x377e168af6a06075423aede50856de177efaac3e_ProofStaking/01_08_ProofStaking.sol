// SPDX-License-Identifier: None
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IProofStaking.sol";

contract ProofStaking is Ownable, IProofStaking {
    using SafeERC20 for IERC20;
    
    mapping(address => UserInfo) public userInfo;
    mapping(address => uint256) public rewardDebt;
    mapping(address => uint256) public totalRewardDeposits;

    uint256 public totalStakedAmount;
    uint256 public unstakeDuration = 2 days;
    uint256 public unallocatedETH;
    uint256 public accRewardsPerShare;
    uint256 public ethDebt;
    uint256 public globalETHCollected;

    address[] userList;
    address[] depositorList;

    IERC20 public immutable proofToken;
    
    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);

    constructor(address _proofToken) {
        proofToken = IERC20(_proofToken);
    }

    function stake(uint256 _amount) external override {
        UserInfo storage user = userInfo[msg.sender];
        uint256 pending;
        if (_amount == 0) { revert('cant stake 0'); }

        if (!user.existingStaker) {
            user.existingStaker = true;
            userList.push(msg.sender);
        }

        if (user.stakedAmount > 0) {
            pending = ((user.stakedAmount * accRewardsPerShare) / 1e24) - user.rewardDebt;
        }

        uint256 pendingUnstake = user.pendingUnstakeAmount;
        if (pendingUnstake >= _amount) {
            user.pendingUnstakeAmount -= _amount;
        } else {
            uint256 tokensNeeded = _amount - pendingUnstake;
            user.pendingUnstakeAmount = 0;
            proofToken.safeTransferFrom(msg.sender, address(this), tokensNeeded);
        }
        
        user.stakedAmount += _amount;
        user.rewardDebt = user.stakedAmount * accRewardsPerShare / 1e24;
        totalStakedAmount += _amount;

        if(pending > 0) {
            user.claimableRewards += pending;
        }
        
        emit Stake(msg.sender, _amount);
    }


    function unstake(uint256 _amount) external override {
        UserInfo storage user = userInfo[msg.sender];
        if (_amount == 0) { revert('cant unstake 0'); }
        if (user.stakedAmount < _amount) { revert('not enough staked'); }
        uint256 pending = ((user.stakedAmount * accRewardsPerShare) / 1e24) - user.rewardDebt;
        user.stakedAmount -= _amount;
        user.lastUnstakeTime = block.timestamp;
        user.pendingUnstakeAmount += _amount;
        user.rewardDebt = user.stakedAmount * accRewardsPerShare / 1e24;
        totalStakedAmount -= _amount;

        if(pending > 0) {
            user.claimableRewards += pending;
        }

        emit Unstake(msg.sender, _amount);
    }

    function restakeTokens() external override {
        UserInfo storage user = userInfo[msg.sender];
        uint256 pending;
        uint256 amountToRestake = user.pendingUnstakeAmount;
        if (amountToRestake == 0) { revert('No pending unstakes'); }

        if (user.stakedAmount > 0) {
            pending = ((user.stakedAmount * accRewardsPerShare) / 1e24) - user.rewardDebt;
        }

        user.pendingUnstakeAmount = 0;
        user.stakedAmount += amountToRestake;
        user.rewardDebt = user.stakedAmount * accRewardsPerShare / 1e24;
        totalStakedAmount += amountToRestake;

        if(pending > 0) {
            user.claimableRewards += pending;
        }
    }

    function claimUnstakedToken() external override {
        UserInfo storage user = userInfo[msg.sender];
        uint256 toWithdraw = user.pendingUnstakeAmount;
        if (toWithdraw == 0) { revert('No pending unstakes'); }
        if (block.timestamp < user.lastUnstakeTime + unstakeDuration) { revert('unstake not ready'); }
        user.pendingUnstakeAmount = 0;
        proofToken.safeTransfer(msg.sender, toWithdraw);
        emit Withdraw(msg.sender, toWithdraw);
    }


    function claimRewards() public override {
        UserInfo storage user = userInfo[msg.sender];
        user.claimableRewards += ((user.stakedAmount * accRewardsPerShare) / 1e24) - user.rewardDebt;
        uint256 claimable = user.claimableRewards;
        if (claimable == 0) { revert('no rewards to claim'); }  
        user.rewardDebt = user.stakedAmount * accRewardsPerShare / 1e24;
        uint256 amount = address(this).balance > claimable ? claimable : address(this).balance;
        user.claimableRewards -= amount;
        user.claimedAmount += amount; //for analytics only
        (bool sent, ) = msg.sender.call{value: amount}("");
        if (!sent) { revert('sending ETH failed'); }
        emit Claim(msg.sender, amount);
    }
    

    function setUnstakingDuration(uint256 newDuration) external override onlyOwner {
        unstakeDuration = newDuration;
    }

    function refreshPool() external override onlyOwner {
        uint256 amountToAdd = unallocatedETH;
        if (amountToAdd == 0) { revert('no unallocated ETH'); }
        if (totalStakedAmount == 0) { revert('"no holders'); }

        unallocatedETH = 0;
        accRewardsPerShare += (amountToAdd * 1e24) / totalStakedAmount; //precision
    }

    receive() external payable {
        uint256 amount = msg.value;
        if (amount == 0) { revert('no ETH'); }
        if (totalRewardDeposits[msg.sender] == 0) {
            depositorList.push(msg.sender);
        }
        totalRewardDeposits[msg.sender] += amount;
        globalETHCollected += amount;
        if (totalStakedAmount == 0) {
            unallocatedETH += amount;
        } else {
            if (ethDebt == 0) {
                accRewardsPerShare += (amount * 1e24) / totalStakedAmount;
            } else if (ethDebt >= amount) {
                ethDebt -= amount;
            } else { //amount > ethDebt and we have some ethDebt
                accRewardsPerShare += ((amount - ethDebt) * 1e24) / totalStakedAmount;
                ethDebt = 0;
            }
            
        }
    }

    function emergencyWithdrawUnclaimedRewards() external onlyOwner {
        uint256 amount = address(this).balance;
        ethDebt += amount;
        (bool sent, ) = msg.sender.call{value: amount}("");
        if (!sent) { revert('sending ETH failed'); }
    }


    //getters

    function getClaimableRewards(address _staker) external view returns (uint256) {
        UserInfo storage user = userInfo[_staker];
        return user.claimableRewards + ((user.stakedAmount * accRewardsPerShare) / 1e24) - user.rewardDebt;
    }

    function getStakers() external view returns (address[] memory) {
        return userList;
    }

    function getDepositors() external view returns (address[] memory) {
        return depositorList;
    }

    function getClaimableUnstakedToken(address _staker) external view returns (uint256) {
        UserInfo storage user = userInfo[_staker];
        if (block.timestamp >= user.lastUnstakeTime + unstakeDuration) {
            return user.pendingUnstakeAmount;
        } else {
            return 0;
        }
    }

    function getPendingUnstakeAmount(address _staker) external view returns (uint256) {
        return userInfo[_staker].pendingUnstakeAmount;
    }

    function getTotalDepositAmount(address user) external view returns (uint256) {
        return totalRewardDeposits[user];
    }
}