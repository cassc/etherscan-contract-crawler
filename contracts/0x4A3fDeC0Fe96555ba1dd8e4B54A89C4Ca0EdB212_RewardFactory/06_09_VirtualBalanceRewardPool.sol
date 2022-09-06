// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
/**
 *Submitted for verification at Etherscan.io on 2020-07-17
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/
* Synthetix: VirtualBalanceRewardPool.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "./utils/Interfaces.sol";
import "./utils/MathUtil.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VirtualBalanceRewardPool {
    using SafeERC20 for IERC20;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    error Unauthorized();

    uint256 public constant DURATION = 7 days;
    uint256 public constant NEW_REWARD_RATIO = 830;

    IBaseRewardsPool public immutable deposits;
    IERC20 public immutable rewardToken;
    address public immutable operator;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public queuedRewards;
    uint256 public currentRewards;
    uint256 public historicalRewards;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    constructor(
        address deposit_,
        address reward_,
        address op_
    ) {
        deposits = IBaseRewardsPool(deposit_);
        rewardToken = IERC20(reward_);
        operator = op_;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyDeposits() {
        if (msg.sender != address(deposits)) {
            revert Unauthorized();
        }
        _;
    }

    function totalSupply() public view returns (uint256) {
        return deposits.totalSupply();
    }

    function balanceOf(address account) public view returns (uint256) {
        return deposits.balanceOf(account);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        // solhint-disable-next-line
        return MathUtil.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        uint256 totalSupplyMemory = totalSupply();
        if (totalSupplyMemory == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalSupplyMemory);
    }

    function earned(address account) public view returns (uint256) {
        return (balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + rewards[account];
    }

    //update reward, emit, call linked reward's stake
    function stake(address _account, uint256 amount) external updateReward(_account) onlyDeposits {
        emit Staked(_account, amount);
    }

    function withdraw(address _account, uint256 amount) public updateReward(_account) onlyDeposits {
        emit Withdrawn(_account, amount);
    }

    function getReward(address _account) public updateReward(_account) {
        uint256 reward = earned(_account);
        if (reward > 0) {
            rewards[_account] = 0;
            rewardToken.safeTransfer(_account, reward);
            emit RewardPaid(_account, reward);
        }
    }

    function getReward() external {
        getReward(msg.sender);
    }

    function donate(uint256 _amount) external {
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
        queuedRewards = queuedRewards + _amount;
    }

    function queueNewRewards(uint256 _rewards) external {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        _rewards = _rewards + queuedRewards;
        // solhint-disable-next-line
        if (block.timestamp >= periodFinish) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
            return;
        }

        //et = now - (finish-duration)
        // solhint-disable-next-line
        uint256 elapsedTime = block.timestamp - (periodFinish - DURATION);
        //current at now: rewardRate * elapsedTime
        uint256 currentAtNow = rewardRate * elapsedTime;
        uint256 queuedRatio = (currentAtNow * 1000) / _rewards;
        if (queuedRatio < NEW_REWARD_RATIO) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
        } else {
            queuedRewards = _rewards;
        }
    }

    function notifyRewardAmount(uint256 reward) internal updateReward(address(0)) {
        historicalRewards = historicalRewards + reward;
        // solhint-disable-next-line
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / DURATION;
        } else {
            // solhint-disable-next-line
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            reward = reward + leftover;
            rewardRate = reward / DURATION;
        }
        currentRewards = reward;
        // solhint-disable-next-line
        lastUpdateTime = block.timestamp;
        // solhint-disable-next-line
        periodFinish = block.timestamp + DURATION;
        emit RewardAdded(reward);
    }
}