// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/utils/Votes.sol)
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Checkpoints.sol';

/**
 * @dev This is a base abstract contract that tracks voting units, which are a measure of voting power that can be
 * transferred, and provides a system of vote delegation, where an account can delegate its voting units to a sort of
 * "representative" that will pool delegated voting units from different accounts and can then use it to vote in
 * decisions. In fact, voting units _must_ be delegated in order to count as actual votes, and an account has to
 * delegate those votes to itself if it wishes to participate in decisions and does not have a trusted representative.
 *
 * This contract is often combined with a token contract such that voting units correspond to token units. For an
 * example, see {ERC721Votes}.
 *
 * The full history of delegate votes is tracked on-chain so that governance protocols can consider votes as distributed
 * at a particular block number to protect against flash loans and double voting. The opt-in delegate system makes the
 * cost of this history tracking optional.
 *
 * When using this module the derived contract must implement {_getVotingUnits} (for example, make it return
 * {ERC721-balanceOf}), and can use {_transferVotingUnits} to track a change in the distribution of those units (in the
 * previous example, it would be included in {ERC721-_beforeTokenTransfer}).
 *
 * _Available since v4.5._
 */
abstract contract Votes {
  using Checkpoints for Checkpoints.History;

  error SIGNATURE_EXPIRED();
  error BLOCK_NOT_YET_MINED();
  error INVALID();

  /**
   * @dev Emitted when an account changes their delegate.
   */
  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );

  /**
   * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
   */
  event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

  mapping(address => address) private _delegation;
  mapping(address => Checkpoints.History) private _delegateCheckpoints;
  Checkpoints.History private _totalCheckpoints;

  /**
   * @dev Returns the current amount of votes that `account` has.
   */
  function getVotes(address account) public view virtual returns (uint256) {
    return _delegateCheckpoints[account].latest();
  }

  /**
   * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
   *
   * Requirements:
   *
   * - `blockNumber` must have been already mined
   */
  function getPastVotes(
    address account,
    uint256 blockNumber
  ) public view virtual returns (uint256) {
    return _delegateCheckpoints[account].getAtBlock(blockNumber);
  }

  /**
   * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
   *
   * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
   * Votes that have not been delegated are still part of total supply, even though they would not participate in a
   * vote.
   *
   * Requirements:
   *
   * - `blockNumber` must have been already mined
   */
  function getPastTotalSupply(uint256 blockNumber) public view virtual returns (uint256) {
    if (blockNumber >= block.number) revert BLOCK_NOT_YET_MINED();
    return _totalCheckpoints.getAtBlock(blockNumber);
  }

  /**
   * @dev Returns the current total supply of votes.
   */
  function _getTotalSupply() internal view virtual returns (uint256) {
    return _totalCheckpoints.latest();
  }

  /**
   * @dev Returns the delegate that `account` has chosen.
   */
  function delegates(address account) public view virtual returns (address) {
    return _delegation[account];
  }

  /**
   * @dev Delegates votes from the sender to `delegatee`.
   */
  function delegate(address delegatee) public virtual {
    _delegate(msg.sender, delegatee);
  }

  /**
   * @dev Delegate all of `account`'s voting units to `delegatee`.
   *
   * Emits events {DelegateChanged} and {DelegateVotesChanged}.
   */
  function _delegate(address account, address delegatee) internal virtual {
    address oldDelegate = delegates(account);
    _delegation[account] = delegatee;

    emit DelegateChanged(account, oldDelegate, delegatee);
    _moveDelegateVotes(oldDelegate, delegatee, _getVotingUnits(account));
  }

  /**
   * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
   * should be zero. Total supply of voting units will be adjusted with mints and burns.
   */
  function _transferVotingUnits(address from, address to, uint256 amount) internal virtual {
    if (from == address(0)) {
      _totalCheckpoints.push(_add, amount);
    }
    if (to == address(0)) {
      _totalCheckpoints.push(_subtract, amount);
    }
    _moveDelegateVotes(delegates(from), delegates(to), amount);
  }

  /**
   * @dev Moves delegated votes from one delegate to another.
   */
  function _moveDelegateVotes(address from, address to, uint256 amount) private {
    if (from != to && amount > 0) {
      if (from != address(0)) {
        (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[from].push(_subtract, amount);
        emit DelegateVotesChanged(from, oldValue, newValue);
      }
      if (to != address(0)) {
        (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[to].push(_add, amount);
        emit DelegateVotesChanged(to, oldValue, newValue);
      }
    }
  }

  function _add(uint256 a, uint256 b) internal pure returns (uint256) {
    return a + b;
  }

  function _subtract(uint256 a, uint256 b) internal pure returns (uint256) {
    return a - b;
  }

  /**
   * @dev Must return the voting units held by an account.
   */
  function _getVotingUnits(address) internal view virtual returns (uint256);
}