// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/governance/TimelockController.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import './Lottery.sol';
import './Token.sol';


contract LotteryController is TimelockController, Pausable, ReentrancyGuard {
  using Address for address payable;

  struct Revenue {
    uint256 blockNumber;
    uint256 value;
    uint256 totalValue;
  }

  bytes32 public constant DRAW_ROLE = keccak256('DRAW_ROLE');

  LotteryToken public immutable token;
  Lottery public immutable lottery;

  uint256 private _totalWithdrawn = 0;
  Revenue[] private _revenue;
  mapping(address => uint256) public lastWithdrawalBlock;

  constructor(
      LotteryToken _token,
      Lottery _lottery,
      address[] memory proposers,
      address[] memory executors)
      TimelockController(7 days, proposers, executors, msg.sender)
  {
    token = _token;
    lottery = _lottery;
    _setRoleAdmin(DRAW_ROLE, TIMELOCK_ADMIN_ROLE);
    _setupRole(DRAW_ROLE, address(0));
  }

  function pause() public onlyRole(TIMELOCK_ADMIN_ROLE) {
    _pause();
    lottery.pause();
  }

  function unpause() public onlyRole(TIMELOCK_ADMIN_ROLE) {
    _unpause();
    lottery.unpause();
  }

  function _getLastRoundTotalRevenue() private view returns (uint256) {
    if (_revenue.length > 0) {
      return _revenue[_revenue.length - 1].totalValue;
    } else {
      return 0;
    }
  }

  function canDraw() public view returns (bool) {
    return lottery.canDraw();
  }

  function draw(uint64 vrfSubscriptionId, bytes32 vrfKeyHash, uint32 callbackGasLimit)
      public whenNotPaused nonReentrant onlyRoleOrOpenRole(DRAW_ROLE)
  {
    lottery.draw(vrfSubscriptionId, vrfKeyHash, callbackGasLimit);
    uint256 totalValue = address(this).balance - _totalWithdrawn;
    _revenue.push(Revenue({
      blockNumber: block.number,
      value: totalValue - _getLastRoundTotalRevenue(),
      totalValue: totalValue
    }));
  }

  function findWinners() public whenNotPaused onlyRoleOrOpenRole(DRAW_ROLE) {
    lottery.findWinners();
  }

  function closeRound() public whenNotPaused onlyRoleOrOpenRole(DRAW_ROLE) {
    lottery.closeRound();
  }

  function numRevenueRecords() public view returns (uint) {
    return _revenue.length;
  }

  function getRevenueRecord(uint index) public view returns (uint256, uint256) {
    require(index < _revenue.length, 'invalid index');
    Revenue storage revenue = _revenue[index];
    return (revenue.blockNumber, revenue.value);
  }

  function getAccountRevenueRecord(address account, uint index)
      public view returns (uint256 blockNumber, uint256 globalRevenue, uint256 accountRevenue)
  {
    require(index < _revenue.length, 'invalid index');
    Revenue storage revenue = _revenue[index];
    blockNumber = revenue.blockNumber;
    globalRevenue = revenue.value;
    accountRevenue = revenue.value * token.getPastVotes(account, blockNumber) /
        token.getPastTotalSupply(blockNumber);
  }

  function _getFirstUnclaimedRound(address account) private view returns (uint) {
    uint256 nextWithdrawalBlock = lastWithdrawalBlock[account] + 1;
    uint i = 0;
    uint j = _revenue.length;
    while (j > i) {
      uint k = i + ((j - i) >> 1);
      if (nextWithdrawalBlock > _revenue[k].blockNumber) {
        i = k + 1;
      } else {
        j = k;
      }
    }
    return i;
  }

  function getUnclaimedRevenue(address account) public view returns (uint256 revenue) {
    revenue = 0;
    for (uint i = _getFirstUnclaimedRound(account); i < _revenue.length; i++) {
      uint256 pastBlock = _revenue[i].blockNumber;
      revenue += _revenue[i].value * token.getPastVotes(account, pastBlock) /
          token.getPastTotalSupply(pastBlock);
    }
  }

  function withdraw(address payable account) public whenNotPaused nonReentrant {
    require(_revenue.length > 0, 'nothing to withdraw');
    uint256 amount = getUnclaimedRevenue(account);
    require(amount > 0, 'no revenue is available for withdrawal');
    _totalWithdrawn += amount;
    lastWithdrawalBlock[account] = _revenue[_revenue.length - 1].blockNumber;
    account.sendValue(amount);
  }
}