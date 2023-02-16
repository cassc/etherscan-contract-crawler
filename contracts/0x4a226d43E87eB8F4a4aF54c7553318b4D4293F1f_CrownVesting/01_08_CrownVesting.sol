// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { VucaOwnable } from "./VucaOwnable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// VUCA + Pellar + LightLink 2023

contract CrownVesting is VucaOwnable {
  using SafeERC20 for IERC20;

  struct LockUpItem {
    bool claimed;
    uint32 claimable_at;
    uint256 amount;
  }

  address public crownToken = 0xF3Bb9F16677F2B86EfD1DFca1c141A99783Fde58;

  mapping(address => LockUpItem[]) public items;

  event VestingCreated(address indexed id, uint256 amount, uint32 claimableAt);
  event VestingUpdated(address indexed id, uint256 amount, uint32 claimableAt);
  event VestingClaimed(address indexed id, uint256 amount);

  function createVesting(
    address _identification,
    uint256 _amount,
    uint32 _claimableAt
  ) external {
    require(_amount > 0, "Invalid amount");
    require(_claimableAt > block.timestamp, "Invalid time");

    LockUpItem memory lockUpItem = LockUpItem({ claimable_at: _claimableAt, amount: _amount, claimed: false });
    items[_identification].push(lockUpItem);

    IERC20(crownToken).safeTransferFrom(msg.sender, address(this), _amount);

    emit VestingCreated(_identification, _amount, _claimableAt);
  }

  function claimToken(address _identification, uint256 _lockUpId) external {
    require(_identification == msg.sender || owner() == msg.sender, "Not authorized");
    require(items[_identification].length > _lockUpId, "Invalid lockup id");

    LockUpItem storage lockUpItem = items[_identification][_lockUpId];
    require(lockUpItem.claimable_at <= block.timestamp, "Not claimable yet");
    require(!lockUpItem.claimed, "Already claimed");

    lockUpItem.claimed = true;

    uint256 amount = lockUpItem.amount;

    IERC20(crownToken).safeTransfer(_identification, amount);

    emit VestingClaimed(_identification, amount);
  }

  function updateClaimableAt(address _identification, uint256 _lockUpId, uint32 _claimableAt) external onlyOwner {
    require(items[_identification].length > _lockUpId, "Invalid lockup id");
    require(_claimableAt > block.timestamp, "Invalid time");

    LockUpItem storage lockUpItem = items[_identification][_lockUpId];
    require(!lockUpItem.claimed, "Already claimed");

    lockUpItem.claimable_at = _claimableAt;

    emit VestingCreated(_identification, lockUpItem.amount, _claimableAt);
  }
}