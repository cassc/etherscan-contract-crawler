// SPDX-License-Identifier: UNLICENSED

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
    mapping(address => uint256) public lastUpdate;

    uint256 public aprPercent = 15;

    uint256 public stakersCount;

    constructor(
        address _token,
        address _rewardToken,
        address _owner,
        uint256 _aprPercent
    ) {
        token = IERC20(_token);
        rewardToken = IERC20(_rewardToken);
        ownAddr = _owner;
        aprPercent = _aprPercent;
    }

    function balanceOf(address account) external view returns (uint256) {
        return deposits[account] + pendingReward(account);
    }

    function stake(uint256 amount) public virtual {
        uint256 reward = pendingReward(msg.sender);
        if (reward > 0) {
            rewardToken.safeTransfer(msg.sender, reward);
        }
        uint256 deposit = deposits[msg.sender];
        deposits[msg.sender] = deposits[msg.sender] + amount;
        lastUpdate[msg.sender] = block.timestamp;
        token.safeTransferFrom(msg.sender, ownAddr, amount.mul(fee).div(1000));
        token.safeTransferFrom(
            msg.sender,
            address(this),
            amount.sub(amount.mul(fee).div(1000))
        );
        if (deposit == 0) {
            stakersCount += 1;
        }
    }

    function unstake(uint256 amount) public virtual {
        require(
            deposits[msg.sender] >= amount,
            "Not enough user balance to withdraw"
        );
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
        return
            deposits[account].mul(aprPercent).div(1000).mul(stakedTime).div(
                30 days
            );
    }

    function harvest() external {
        require(deposits[msg.sender] > 0, "No balance to withdraw");
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