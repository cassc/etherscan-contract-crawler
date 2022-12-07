//Made with Student Coin Terminal
//SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Configurable} from "../utils/Configurable.sol";
import {ITokenERC20} from "../interfaces/ITokenERC20.sol";

contract Vesting is AccessControl, Configurable {
  // structs
  struct Shareholder {
    address account;
    uint8 shares;
  }
  struct Member {
    Shareholder shareholder;
    uint256 collected;
    uint8 lastCheckpoint;
  }

  // storage
  ITokenERC20 public erc20;
  mapping(address => Member) public members;

  // config
  uint256 public immutable supply;
  uint8 public immutable duration; // 1-60
  uint256 public startTime;

  // events
  event Collected(address sender, uint256 amount, uint8 lastCheckpoint, uint8 newCheckpoint);

  // errors
  error InvalidConfig(uint256 supply_, uint8 duration_);
  error SharesNotInTheRange(address account, uint256 shares);
  error SharesNotSumTo100(uint256 total);
  error InvalidMember(address member);
  error NothingToCollect(address member, uint8 collected, uint8 checkpoint);
  error SupplyMismatch(uint256 balance, uint256 declared);
  error ConfigurationBalanceMishmatch(uint256 amount, uint256 balance);

  // modifiers
  modifier onlyMember() {
    if (members[msg.sender].shareholder.shares == 0) {
      revert InvalidMember(msg.sender);
    }
    _;
  }

  constructor(bytes memory arguments_) {
    // tx members
    address sender = tx.origin;

    (uint256 supply_, uint8 duration_, Shareholder[] memory shareholders_) = abi.decode(
      arguments_,
      (uint256, uint8, Shareholder[])
    );

    // check supply and duration
    if (supply_ == 0 || duration_ == 0 || duration_ > 60) {
      revert InvalidConfig(supply_, duration_);
    }

    // check members
    uint8 totalShares = 0;
    for (uint8 i = 0; i < shareholders_.length; i++) {
      Member memory member = Member(shareholders_[i], 0, 0);
      uint8 shares = member.shareholder.shares;
      address account = member.shareholder.account;

      // check address and individual shares
      if (account == address(0x0)) {
        revert InvalidMember(account);
      }
      if (shares == 0 || shares > 100) {
        revert SharesNotInTheRange(account, shares);
      }

      members[account] = member;
      totalShares += shares;
    }

    // check sum of shares
    if (totalShares != 100) {
      revert SharesNotSumTo100(totalShares);
    }

    // storage
    supply = supply_;
    duration = duration_;

    // base role
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
  }

  function configure(address erc20_)
    external
    onlyInState(State.UNCONFIGURED)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    // tx.members
    startTime = block.timestamp;

    // token
    erc20 = ITokenERC20(erc20_);

    // check balance vs supply
    uint256 balance = erc20.balanceOf(address(this));
    if (balance != supply) {
      revert SupplyMismatch(balance, supply);
    }

    // check configuration vs balance
    uint256 vestingSupply = erc20.vestingSupply();
    if (vestingSupply != balance) {
      revert ConfigurationBalanceMishmatch(vestingSupply, balance);
    }

    // state
    state = State.CONFIGURED;
  }

  function endTime() public view onlyInState(State.CONFIGURED) returns (uint256) {
    // start time + X months (where X is duration)
    return startTime + (30 days * duration);
  }

  function currentCheckpoint() public view onlyInState(State.CONFIGURED) returns (uint8) {
    // not started case -> 0
    if (startTime > block.timestamp) return 0;

    // checkpoint = (now - start time) / month
    uint256 checkpoint = (block.timestamp - startTime) / 30 days;

    // checkpoint or cap to duration -> 0 ~ duration
    return uint8(Math.min(checkpoint, uint256(duration)));
  }

  function collect() external onlyInState(State.CONFIGURED) onlyMember {
    // tx.members
    address sender = msg.sender;

    // checkpoints
    uint8 checkpoint = currentCheckpoint();
    uint8 lastCheckpoint = members[sender].lastCheckpoint;

    // revert if nothing to collect
    if (checkpoint <= lastCheckpoint) {
      revert NothingToCollect(sender, lastCheckpoint, checkpoint);
    }

    uint256 amount;
    if (checkpoint == duration) {
      // calculate remaining amount
      amount = (supply * members[sender].shareholder.shares) / 100 - members[sender].collected;
    } else {
      // current checkpoint - last checkpoint
      uint8 checkpointsToCollect = checkpoint - lastCheckpoint;

      // single batch amount
      uint256 partialSupply = supply / duration;

      // shares of single batch
      uint256 singleCheckpointAmount = (partialSupply * members[sender].shareholder.shares) / 100;

      // amount based on shares and checkpoints
      amount = checkpointsToCollect * singleCheckpointAmount;
    }

    // update state and transfer
    members[sender].lastCheckpoint = checkpoint;
    members[sender].collected += amount;
    erc20.transfer(sender, amount);

    // events
    emit Collected(sender, amount, lastCheckpoint, checkpoint);
  }
}