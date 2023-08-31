// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingContract is ReentrancyGuard, Ownable {
    IERC20 public immutable photon;

    uint256 public rewardRate = 430; // 10% APR of price, updateable
    uint256 public constant MAX_REWARD_DURATION = 31536000; // 365 days
    uint256 public rewardDuration = MAX_REWARD_DURATION; // updateable
    uint256 public immutable contractStartTime; // Contract deployment time

    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => StakeInfo) public stakes;

    constructor(IERC20 _photon) {
        photon = _photon;
        contractStartTime = block.timestamp;
    }

     receive() external payable {}

    function stake(uint256 amount) external nonReentrant {
        require(
            photon.transferFrom(_msgSender(), address(this), amount),
            "Transfer Photon tokens failed"
        );

        StakeInfo storage stakeInfo = stakes[_msgSender()];
        if (stakeInfo.amount > 0) {
            uint256 pendingReward = calculateReward(
                stakeInfo.amount,
                stakeInfo.timestamp
            );
            payable(_msgSender()).transfer(pendingReward);
        }

        stakeInfo.amount += amount;
        stakeInfo.timestamp = block.timestamp;
    }

    function unstake(uint256 amount) external nonReentrant {
        StakeInfo storage stakeInfo = stakes[_msgSender()];
        require(stakeInfo.amount >= amount, "Unstaking more than staked");

        uint256 pendingReward = calculateReward(
            stakeInfo.amount,
            stakeInfo.timestamp
        );
        payable(_msgSender()).transfer(pendingReward);

        if (stakeInfo.amount == amount) {
            delete stakes[_msgSender()];
        } else {
            stakeInfo.amount -= amount;
            stakeInfo.timestamp = block.timestamp;
        }

        require(
            photon.transfer(_msgSender(), amount),
            "Transfer Photon tokens failed"
        );
    }

    function claim() external nonReentrant {
        StakeInfo storage stakeInfo = stakes[_msgSender()];
        require(stakeInfo.amount > 0, "No stake to claim rewards from");

        uint256 pendingReward = calculateReward(
            stakeInfo.amount,
            stakeInfo.timestamp
        );
        require(pendingReward > 0, "No rewards to claim");

        payable(_msgSender()).transfer(pendingReward);

        stakeInfo.timestamp = block.timestamp; // update last reward claim time
    }

    function calculateReward(
        uint256 amount,
        uint256 timestamp
    ) public view returns (uint256) {
        uint256 endTime = contractStartTime + rewardDuration;
        uint256 timeDiff;

        if (block.timestamp > endTime) {
            if (timestamp > endTime) return 0;
            timeDiff = endTime - timestamp;
        } else {
            timeDiff = block.timestamp > timestamp
                ? block.timestamp - timestamp
                : 0;
        }

        uint256 reward = (amount * rewardRate * timeDiff) /
            (MAX_REWARD_DURATION * 1_000_000_000);
        return reward;
    }

    function updateRewardRate(uint256 newRate) external onlyOwner {
        rewardRate = newRate;
    }

    function updateRewardDuration(uint256 newDuration) external onlyOwner {
        rewardDuration = newDuration;
    }

    function withdrawStuckETH(uint256 _amount) external onlyOwner {
        require(
            _amount <= address(this).balance,
            "Amount exceeds available ETH"
        );
        payable(owner()).transfer(_amount);
    }

    function emergencyWithdraw() external nonReentrant {
        StakeInfo storage stakeInfo = stakes[_msgSender()];
        require(stakeInfo.amount > 0, "No stake to withdraw");

        uint256 amountToWithdraw = stakeInfo.amount;
        delete stakes[_msgSender()]; // Delete the user's stake info

        require(
            photon.transfer(_msgSender(), amountToWithdraw),
            "Transfer Photon tokens failed"
        );
    }
}