// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Pool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;
    IERC20 public rewardToken;

    uint256 public fee = 10;
    address public ownAddr;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public depositTime;
    mapping(address => uint256) public lastUpdate;

    uint256 public aprPercent = 15;
    uint256 public lockPeriod;
    uint256 public bonus = 100;
    uint256 public bonusEndBlock;
    uint256 public stakersCount;

    constructor(
        address _token,
        address _rewardToken,
        address _owner,
        uint256 _aprPercent,
        uint256 _lockPeriod,
        uint256 _bonus,
        uint256 _bonusEndBlock
    ) {
        token = IERC20(_token);
        rewardToken = IERC20(_rewardToken);
        ownAddr = _owner;
        aprPercent = _aprPercent;
        lockPeriod = _lockPeriod;
        bonus = _bonus;
        bonusEndBlock = _bonusEndBlock;
    }

    function balanceOf(address account) external view returns (uint256) {
        return deposits[account] + pendingReward(account);
    }

    function stake(uint256 amount) public virtual {
        uint256 reward = pendingReward(msg.sender);
        if (reward > 0 && lockPeriod + depositTime[msg.sender] <= block.timestamp) {
            rewardToken.safeTransfer(msg.sender, reward);
            lastUpdate[msg.sender] = block.timestamp;
        }
        
        if (deposits[msg.sender] == 0) {
            depositTime[msg.sender] = block.timestamp;
        }

        if (depositTime[msg.sender] == 0) {
            stakersCount += 1;
        }

        deposits[msg.sender] = deposits[msg.sender] + amount;
        token.safeTransferFrom(msg.sender, ownAddr, amount.mul(fee).div(1000));
        token.safeTransferFrom(
            msg.sender,
            address(this),
            amount.sub(amount.mul(fee).div(1000))
        );
    }

    function unstake(uint256 amount) public virtual {
        require(
            deposits[msg.sender] >= amount,
            "Not enough user balance to withdraw"
        );
        require(lockPeriod + depositTime[msg.sender] <= block.timestamp, "You can't withdraw now.");

        uint256 reward = pendingReward(msg.sender);
        if (reward > 0) {
            rewardToken.safeTransfer(msg.sender, reward);
        }
        if (deposits[msg.sender] == amount) {
            stakersCount -= 1;
        }
        deposits[msg.sender] -= amount;
        lastUpdate[msg.sender] = block.timestamp;
        token.safeTransfer(msg.sender, amount);
    }

    function pendingReward(address account) public view returns (uint256) {
        uint256 stakedTime = block.timestamp - lastUpdate[account];
        uint256 bonusTime;
        if (block.timestamp >= bonusEndBlock && lastUpdate[account] <= bonusEndBlock) {
            bonusTime = block.timestamp - bonusEndBlock;
        }
        uint256 reward = deposits[account].mul(aprPercent).div(1000).mul(stakedTime + (bonusTime * bonus).div(100)).div(30 days);
        return reward;
    }

    function harvest() external {
        require(deposits[msg.sender] > 0, "No balance to withdraw");
        require(lockPeriod + depositTime[msg.sender] <= block.timestamp, "You can't withdraw now.");
        uint256 reward = pendingReward(msg.sender);
        if (reward > 0) {
            rewardToken.transfer(msg.sender, reward);
        }
        lastUpdate[msg.sender] = block.timestamp;
    }

    function getStakerCount() external view returns (uint256) {
        return stakersCount;
    }
}