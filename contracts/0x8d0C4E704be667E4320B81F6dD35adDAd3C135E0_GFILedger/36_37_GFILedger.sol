// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {Context} from "../../../cake/Context.sol";
import {Base} from "../../../cake/Base.sol";
import "../../../cake/Routing.sol" as Routing;

import {Arrays} from "../../../library/Arrays.sol";
import {UserEpochTotals, UserEpochTotal} from "./UserEpochTotals.sol";

import "../../../interfaces/IGFILedger.sol";

using Routing.Context for Context;
using UserEpochTotals for UserEpochTotal;
using Arrays for uint256[];
using SafeERC20 for IERC20Upgradeable;

/**
 * @title GFILedger
 * @notice Track GFI held by owners and ensure the GFI has been accounted for.
 * @author Goldfinch
 */
contract GFILedger is IGFILedger, Base {
  /// Thrown when depositing zero GFI for a position
  error ZeroDepositAmount();
  /// Thrown when withdrawing an invalid amount for a position
  error InvalidWithdrawAmount(uint256 requested, uint256 max);
  /// Thrown when depositing from address(0)
  error InvalidOwnerIndex();
  /// Thrown when querying token supply with an index greater than the supply
  error IndexGreaterThanTokenSupply();

  // All positions in the ledger
  mapping(uint256 => Position) public positions;

  // Which positions an address owns
  mapping(address => uint256[]) private owners;

  /// Total held by each user, while being aware of the deposit epoch
  mapping(address => UserEpochTotal) private totals;

  // Most recent position minted
  uint256 private positionCounter;

  /// @notice Construct the contract
  constructor(Context _context) Base(_context) {}

  /// @inheritdoc IGFILedger
  function deposit(address owner, uint256 amount)
    external
    onlyOperator(Routing.Keys.MembershipOrchestrator)
    returns (uint256 positionId)
  {
    if (amount == 0) {
      revert ZeroDepositAmount();
    }
    positionId = _mintPosition(owner, amount);

    totals[owner].recordIncrease(amount);

    context.gfi().safeTransferFrom(address(context.membershipOrchestrator()), address(this), amount);
  }

  /// @inheritdoc IGFILedger
  function withdraw(uint256 positionId) external onlyOperator(Routing.Keys.MembershipOrchestrator) returns (uint256) {
    return _withdraw(positionId);
  }

  /// @inheritdoc IGFILedger
  function withdraw(uint256 positionId, uint256 amount)
    external
    onlyOperator(Routing.Keys.MembershipOrchestrator)
    returns (uint256)
  {
    Position memory position = positions[positionId];

    if (amount > position.amount) revert InvalidWithdrawAmount(amount, position.amount);
    if (amount == position.amount) return _withdraw(positionId);

    positions[positionId].amount -= amount;
    totals[position.owner].recordDecrease(amount, position.depositTimestamp);

    context.gfi().safeTransfer(position.owner, amount);

    emit GFIWithdrawal({
      owner: position.owner,
      positionId: positionId,
      withdrawnAmount: amount,
      remainingAmount: position.amount - amount,
      depositTimestamp: position.depositTimestamp
    });

    return amount;
  }

  /// @inheritdoc IGFILedger
  function balanceOf(address addr) external view returns (uint256 balance) {
    return owners[addr].length;
  }

  /// @inheritdoc IGFILedger
  function ownerOf(uint256 positionId) external view returns (address) {
    return positions[positionId].owner;
  }

  /// @inheritdoc IGFILedger
  function totalsOf(address addr) external view returns (uint256 eligibleAmount, uint256 totalAmount) {
    return totals[addr].getTotals();
  }

  /// @inheritdoc IGFILedger
  function totalSupply() public view returns (uint256) {
    return positionCounter;
  }

  /// @inheritdoc IGFILedger
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
    if (index >= owners[owner].length) revert InvalidOwnerIndex();

    return owners[owner][index];
  }

  /// @inheritdoc IGFILedger
  function tokenByIndex(uint256 index) external view returns (uint256) {
    if (index >= totalSupply()) revert IndexGreaterThanTokenSupply();

    return index + 1;
  }

  //////////////////////////////////////////////////////////////////
  // Private

  function _mintPosition(address owner, uint256 amount) private returns (uint256 positionId) {
    positionCounter++;

    positionId = positionCounter;

    positions[positionId] = Position({
      owner: owner,
      ownedIndex: owners[owner].length,
      amount: amount,
      depositTimestamp: block.timestamp
    });

    owners[owner].push(positionId);

    emit GFIDeposit({owner: owner, positionId: positionId, amount: amount});
  }

  function _withdraw(uint256 positionId) private returns (uint256) {
    Position memory position = positions[positionId];
    delete positions[positionId];

    uint256[] storage ownersList = owners[position.owner];
    (, bool replaced) = ownersList.reorderingRemove(position.ownedIndex);
    if (replaced) {
      positions[ownersList[position.ownedIndex]].ownedIndex = position.ownedIndex;
    }

    totals[position.owner].recordDecrease(position.amount, position.depositTimestamp);

    context.gfi().safeTransfer(position.owner, position.amount);

    emit GFIWithdrawal({
      owner: position.owner,
      positionId: positionId,
      withdrawnAmount: position.amount,
      remainingAmount: 0,
      depositTimestamp: position.depositTimestamp
    });

    return position.amount;
  }
}