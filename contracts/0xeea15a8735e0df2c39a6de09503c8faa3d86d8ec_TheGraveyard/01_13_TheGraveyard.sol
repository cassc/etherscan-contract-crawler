/*
     ▒███████▒ ▒█████    ███▄ ▄███▓  ▄▄▄▄     ██▓█████▒███████▒
     ▒ ▒ ▒ ▄▀░▒██▒  ██▒ ▓██▒▀█▀ ██▒ ▓█████▄ ▒▓██▓█   ▀▒ ▒ ▒ ▄▀░
     ░ ▒ ▄▀▒░ ▒██░  ██▒ ▓██    ▓██░ ▒██▒ ▄██░▒██▒███  ░ ▒ ▄▀▒░
     ▄▀▒   ░▒██   ██░ ▒██    ▒██  ▒██░█▀   ░██▒▓█  ▄  ▄▀▒   ░
     ▒███████▒░ ████▓▒░▒▒██▒   ░██▒▒░▓█  ▀█▓ ░██░▒████▒███████▒
     ░▒▒ ▓░▒░▒░ ▒░▒░▒░ ░░ ▒░   ░  ░░░▒▓███▀▒ ░▓ ░░ ▒░ ░▒▒ ▓░▒░▒
     ░ ▒ ▒ ░ ▒  ░ ▒ ▒░ ░░  ░      ░░▒░▒   ░   ▒  ░ ░  ░ ▒ ▒ ░ ▒
     ░ ░ ░ ░ ░░ ░ ░ ▒   ░      ░     ░    ░   ▒    ░  ░ ░ ░ ░ ░
     ░ ░        ░ ░  ░       ░   ░ ░        ░    ░    ░ ░
   ▄████  ██▀███   ▄▄▄      ██▒   █▓▓█████▓██   ██▓ ▄▄▄      ██▀███   ▓█████▄
▒ ██▒ ▀█▒▓██ ▒ ██▒▒████▄   ▓██░   █▒▓█   ▀ ▒██  ██▒▒████▄   ▓██ ▒ ██▒ ▒██▀ ██▌
░▒██░▄▄▄░▓██ ░▄█ ▒▒██  ▀█▄  ▓██  █▒░▒███    ▒██ ██░▒██  ▀█▄ ▓██ ░▄█ ▒ ░██   █▌
░░▓█  ██▓▒██▀▀█▄  ░██▄▄▄▄██  ▒██ █░░▒▓█  ▄  ░ ▐██▓░░██▄▄▄▄██▒██▀▀█▄  ▒░▓█▄   ▌
░▒▓███▀▒░░██▓ ▒██▒ ▓█   ▓██   ▒▀█░  ░▒████  ░ ██▒▓░ ▓█   ▓██░██▓ ▒██▒░░▒████▓
 ░▒   ▒  ░ ▒▓ ░▒▓░ ▒▒   ▓▒█   ░ ▐░  ░░ ▒░    ██▒▒▒  ▒▒   ▓▒█░ ▒▓ ░▒▓░░ ▒▒▓  ▒
  ░   ░    ░▒ ░ ▒░  ░   ▒▒    ░ ░░   ░ ░   ▓██ ░▒░   ░   ▒▒   ░▒ ░ ▒░  ░ ▒  ▒
░ ░   ░ ░   ░   ░   ░   ▒       ░░     ░   ▒ ▒ ░░    ░   ▒     ░   ░   ░ ░  ░
    ░     ░           ░        ░     ░   ░ ░           ░     ░         ░
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract StakedTokenWrapper {
  uint256 public totalSupply;

  mapping(address => uint256) private _balances;
  IERC20 public stakedToken;

  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function stakeFor(address forWhom, uint128 amount) public payable virtual {
    IERC20 st = stakedToken;
    if (st == IERC20(address(0))) {
      //eth
      unchecked {
        totalSupply += msg.value;
        _balances[forWhom] += msg.value;
      }
    } else {
      require(msg.value == 0, "non-zero eth");
      require(amount > 0, "Cannot stake 0");
      require(
        st.transferFrom(msg.sender, address(this), amount),
        "staked token transfer failed"
      );
      unchecked {
        totalSupply += amount;
        _balances[forWhom] += amount;
      }
    }
    emit Staked(forWhom, amount);
  }

  function withdraw(uint128 amount) public virtual {
    require(amount <= _balances[msg.sender], "withdraw: balance is lower");
    unchecked {
      _balances[msg.sender] -= amount;
      totalSupply = totalSupply - amount;
    }
    IERC20 st = stakedToken;
    if (st == IERC20(address(0))) {
      // eth
      (bool success, ) = msg.sender.call{ value: amount }("");
      require(success, "eth transfer failure");
    } else {
      require(
        stakedToken.transfer(msg.sender, amount),
        "staked token transfer failed"
      );
    }
    emit Withdrawn(msg.sender, amount);
  }
}

contract TheGraveyard is StakedTokenWrapper, Ownable, Pausable {
  IERC20 public rewardToken;
  uint256 public rewardRate;
  uint64 public periodFinish;
  uint64 public lastUpdateTime;
  uint128 public rewardPerTokenStored;
  struct UserRewards {
    uint128 userRewardPerTokenPaid;
    uint128 rewards;
  }
  mapping(address => UserRewards) public userRewards;

  event RewardAdded(uint256 reward);
  event RewardPaid(address indexed user, uint256 reward);

  constructor(IERC20 _rewardToken, IERC20 _stakedToken) {
    rewardToken = _rewardToken;
    stakedToken = _stakedToken;
    _pause();
  }

  modifier updateReward(address account) {
    uint128 _rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    rewardPerTokenStored = _rewardPerTokenStored;
    userRewards[account].rewards = earned(account);
    userRewards[account].userRewardPerTokenPaid = _rewardPerTokenStored;
    _;
  }

  function lastTimeRewardApplicable() public view returns (uint64) {
    uint64 blockTimestamp = uint64(block.timestamp);
    return blockTimestamp < periodFinish ? blockTimestamp : periodFinish;
  }

  function rewardPerToken() public view returns (uint128) {
    uint256 totalStakedSupply = totalSupply;
    if (totalStakedSupply == 0) {
      return rewardPerTokenStored;
    }
    unchecked {
      uint256 rewardDuration = lastTimeRewardApplicable() -
        lastUpdateTime;
      return
        uint128(
          rewardPerTokenStored +
            (rewardDuration * rewardRate * 1e18) /
            totalStakedSupply
        );
    }
  }

  function earned(address account) public view returns (uint128) {
    unchecked {
      return
        uint128(
          (balanceOf(account) *
            (rewardPerToken() -
              userRewards[account].userRewardPerTokenPaid)) /
            1e18 +
            userRewards[account].rewards
        );
    }
  }

  function stake(uint128 amount) external payable whenNotPaused {
    stakeFor(msg.sender, amount);
  }

  function stakeFor(address forWhom, uint128 amount) public payable override updateReward(forWhom) whenNotPaused {
    super.stakeFor(forWhom, amount);
  }

  function withdraw(uint128 amount) public override updateReward(msg.sender) whenNotPaused {
    super.withdraw(amount);
  }

  function exit() external whenNotPaused {
    getReward();
    withdraw(uint128(balanceOf(msg.sender)));
  }

  function getReward() public updateReward(msg.sender) whenNotPaused {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      userRewards[msg.sender].rewards = 0;
      require(
        rewardToken.transfer(msg.sender, reward),
        "reward transfer failed"
      );
      emit RewardPaid(msg.sender, reward);
    }
  }

  function setRewardParams(uint128 reward, uint64 duration) external onlyOwner {
    unchecked {
      require(reward > 0);
      rewardPerTokenStored = rewardPerToken();
      uint64 blockTimestamp = uint64(block.timestamp);
      uint256 maxRewardSupply = rewardToken.balanceOf(address(this));
      if (rewardToken == stakedToken) maxRewardSupply -= totalSupply;
      uint256 leftover = 0;
      if (blockTimestamp >= periodFinish) {
        rewardRate = reward / duration;
      } else {
        uint256 remaining = periodFinish - blockTimestamp;
        leftover = remaining * rewardRate;
        rewardRate = (reward + leftover) / duration;
      }
      require(reward + leftover <= maxRewardSupply, "not enough tokens");
      lastUpdateTime = blockTimestamp;
      periodFinish = blockTimestamp + duration;
      emit RewardAdded(reward);
    }
  }

  function withdrawReward() external onlyOwner {
    uint256 rewardSupply = rewardToken.balanceOf(address(this));
    //ensure funds staked by users can't be transferred out
    if (rewardToken == stakedToken) rewardSupply -= totalSupply;
    require(rewardToken.transfer(msg.sender, rewardSupply));
    rewardRate = 0;
    periodFinish = uint64(block.timestamp);
  }

  // Public accessor methods for pausing
  function pause() public onlyOwner { _pause(); }
  function unpause() public onlyOwner { _unpause(); }
}

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
   /___/

* Synthetix: YFIRewards.sol
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