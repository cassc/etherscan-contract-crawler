// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CISXStaking is Ownable2Step {
  using SafeERC20 for IERC20;

  struct StakeItem {
    bool unstaked;
    uint8 lock_type;
    uint32 start;
    uint256 amount;
  }

  address public carbonToken = 0x04756126F044634C9a0f0E985e60c88a51ACC206;

  uint256 public totalStaked;
  mapping(address => StakeItem[]) public stakes;

  event Staked(address indexed user, uint256 id, uint8 lockType, uint32 start, uint256 amount);
  event Unstaked(address indexed user, uint256 id);

  function getTotalStakedByAccount(address _account) external view returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < stakes[_account].length; i++) {
      if (!stakes[_account][i].unstaked) {
        total += stakes[_account][i].amount;
      }
    }
    return total;
  }

  function getMaxReward(uint256 _amount) public pure returns (uint256) {
    return (((_amount * 15) / 100) * 180 days) / 365 days;
  }

  function stake(uint256 _amount, uint8 _lockType) external {
    require(_lockType < 3, "Invalid lock type");

    uint256 amountRewards = getMaxReward(_amount);
    uint256 stakedAndRewards = totalStaked + getMaxReward(totalStaked);
    require(IERC20(carbonToken).balanceOf(address(this)) >= stakedAndRewards + amountRewards, "Not enough rewards");

    IERC20(carbonToken).safeTransferFrom(msg.sender, address(this), _amount);
    totalStaked += _amount;
    stakes[msg.sender].push(StakeItem({ unstaked: false, start: uint32(block.timestamp), amount: _amount, lock_type: _lockType }));

    emit Staked(msg.sender, stakes[msg.sender].length - 1, _lockType, uint32(block.timestamp), _amount);
  }

  function unstake(uint256 _idx) external {
    StakeItem storage item = stakes[msg.sender][_idx];
    require(!item.unstaked, "Already unstaked");

    uint256[3] memory lockDuration = [60 days, 90 days, uint256(180 days)];
    uint8[3] memory apys = [5, 12, 15];
    require(block.timestamp - item.start >= lockDuration[item.lock_type], "Lock period not passed");

    uint256 rewards = (((item.amount * apys[item.lock_type]) / 100) * lockDuration[item.lock_type]) / 365 days;
    uint256 total = rewards + item.amount; // rewards + amount

    totalStaked -= item.amount;
    IERC20(carbonToken).safeTransfer(msg.sender, total);
    item.unstaked = true;

    emit Unstaked(msg.sender, _idx);
  }

  function withdraw() public onlyOwner {
    uint256 balance = IERC20(carbonToken).balanceOf(address(this));
    uint256 lockedValue = totalStaked + getMaxReward(totalStaked);
    require(balance > lockedValue, "No availble");
    uint256 available = balance - lockedValue;
    IERC20(carbonToken).transfer(msg.sender, available);
  }
}