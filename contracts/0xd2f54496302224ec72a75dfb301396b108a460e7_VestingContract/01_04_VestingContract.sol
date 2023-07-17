// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct Member {
  address account;
  uint256 totalAmount;
  uint256 claimedAmount;
  uint256 remainingAmount;
  uint256 startTime;
  uint256 endTime;
  bool locked;
}

contract VestingContract is Ownable {

  event Claimed(address account, uint256 amount);

  event Added(address account, uint256 amount);
  event Removed(address account, uint256 amount);

  IERC20 kataToken;

  string public name;

  mapping(address => Member) public members;

  uint256 public tgeTime;
  uint256 public tgePercent;
  uint256 public cliffDuration;
  uint256 public cliffPercent;
  uint256 public linearDuration;

  uint256 public allocatedAmount;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _name beneficiary of tokens after they are released
   * @param _tgeTime duration in seconds of the period in which tokens will begin to vest
   * @param _cliffDuration duration in seconds of the cliff in which tokens will begin to vest
   * @param _cliffPercent dd
   * @param _linearDuration duration in seconds of the period in which the tokens will vest
   */
  constructor(
    string memory _name,
    uint256 _tgeTime,
    uint256 _tgePercent,
    uint256 _cliffDuration,
    uint256 _cliffPercent,
    uint256 _linearDuration
  ) {
    require(_tgeTime > 0, "invalid tgeTime");

    name = _name;
    tgeTime = _tgeTime;
    tgePercent = _tgePercent;
    cliffDuration = _cliffDuration;
    cliffPercent = _cliffPercent;
    linearDuration = _linearDuration;
  }

  modifier onlyMember() {
    require(members[msg.sender].account != address(0), "You are not a valid member");
    _;
  }

  function balance() public view returns (uint256) {
    if (address(kataToken) == address(0)) {
      return 0;
    }

    uint256 _balance = kataToken.balanceOf(address(this));
    _balance -= allocatedAmount;
    return _balance;
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   */
  function claimableAmount(address addr, uint256 timestamp) public view returns (uint256) {
    Member memory _member = members[addr];

    uint256 vested = vestedAmount(addr, timestamp);

    if (vested < _member.claimedAmount) {
      return 0;
    }

    return vested - _member.claimedAmount;
  }

  /**
   * @dev Calculates the amount that has already vested.
   */
  function vestedAmount(address addr, uint256 timestamp) public view returns (uint256) {
    if (address(kataToken) == address(0)) {
      return 0;
    }

    Member memory _member = members[addr];

    if (timestamp < _member.startTime) {
      return 0;
    }

    uint256 _tgeAmount = (_member.totalAmount * tgePercent) / 100;
    uint256 _cliffTime = _member.startTime + cliffDuration;

    if (timestamp < _cliffTime) {
      return _tgeAmount;
    }

    if (_member.endTime != 0) {
      return _member.totalAmount;
    }

    if (timestamp >= (_cliffTime + linearDuration)) {
      return _member.totalAmount;
    }

    uint256 _cliffAmount = (_member.totalAmount * cliffPercent) / 100;

    uint256 _linearAmount = (_member.totalAmount - _tgeAmount) - _cliffAmount;
    _linearAmount = (_linearAmount * (timestamp - _cliffTime)) / linearDuration;

    return _tgeAmount + _cliffAmount + _linearAmount;
  }

  function claim() external onlyMember {
    Member memory _member = members[msg.sender];
    uint256 timestamp = block.timestamp;

    uint256 claimable = claimableAmount(_member.account, timestamp);

    require(claimable > 0, "no tokens claimable");
    require(_member.totalAmount >= (_member.claimedAmount + claimable), "token pool exhausted");

    kataToken.transfer(_member.account, claimable);
    _member.claimedAmount += claimable;
    allocatedAmount -= claimable;

    members[msg.sender] = _member;

    emit Claimed(_member.account, claimable);
  }

  function addMembers(address[] calldata addrs, uint256[] calldata tokenAmounts) external onlyOwner {
    uint256 _balance = balance();

    for (uint256 i = 0; i < addrs.length; i++) {
      Member memory _member = members[addrs[i]];

      require(tokenAmounts[i] <= _balance + _member.remainingAmount, 'allocation would exceed remaining balance');

      if (_member.account == address(0)) {
        _member.account = addrs[i];
        _member.startTime = block.timestamp;

        if (_member.startTime < tgeTime) {
          _member.startTime = tgeTime;
        }
      }

      _member.endTime = 0;
      _member.totalAmount += tokenAmounts[i];

      if (_member.remainingAmount > tokenAmounts[i]) {
        _member.remainingAmount -= tokenAmounts[i];
      } else {
        allocatedAmount += tokenAmounts[i] - _member.remainingAmount;
        _balance -= tokenAmounts[i] - _member.remainingAmount;
        _member.remainingAmount = 0;
      }

      members[addrs[i]] = _member;

      emit Added(addrs[i], tokenAmounts[i]);
    }
  }

  function lockMember(address addr) external onlyOwner {
    require(members[addr].account != address(0), "member not initialized");
    require(!members[addr].locked, "member already locked");
    members[addr].locked = true;
  }

  function setStartTime(address addr, uint256 startTime) external onlyOwner {
    require(members[addr].account != address(0), "member not initialized");
    require(!members[addr].locked, "member locked");
    members[addr].startTime = startTime;
  }

  function removeMember(address addr) external onlyOwner {
    Member memory _member = members[addr];

    uint256 remaining = _member.totalAmount;
    _member.totalAmount = _member.claimedAmount + claimableAmount(addr, block.timestamp);
    remaining -= _member.totalAmount;

    if (_member.locked) {
      // don't refund to pool
      _member.remainingAmount += remaining;
    } else {
      allocatedAmount -= remaining;
    }

    _member.endTime = block.timestamp;

    members[addr] = _member;

    emit Removed(addr, remaining);
  }

  function setKataToken(address _erc) external onlyOwner {
    kataToken = IERC20(_erc);
  }
}