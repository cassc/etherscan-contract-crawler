// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable-new/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-new/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-new/governance/utils/IVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-new/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-new/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-new/proxy/utils/Initializable.sol";
import { IZEROFROST } from "../interfaces/IZEROFROST.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 *
 * _Available since v4.2._
 */

abstract contract ERC20VotesUpgradeable is Initializable, IVotesUpgradeable, ERC20PermitUpgradeable {
  IZEROFROST public zerofrost;
  using SafeMathUpgradeable for uint256;

  function __ERC20Votes_init(address _zerofrost) internal onlyInitializing {
    zerofrost = IZEROFROST(_zerofrost);
  }

  function __ERC20Votes_init_unchained(address _zerofrost) internal onlyInitializing {
    zerofrost = IZEROFROST(_zerofrost);
  }

  struct Checkpoint {
    uint32 fromBlock;
    uint224 votes;
    uint256 timestamp; //
    uint256 balance;
  }

  bytes32 private constant _DELEGATION_TYPEHASH =
    keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  mapping(address => address) private _delegates;
  mapping(address => Checkpoint[]) internal _checkpoints;
  Checkpoint[] private _totalSupplyCheckpoints;

  /**
   * @dev Get the `pos`-th checkpoint for `account`.
   */
  function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
    return _checkpoints[account][pos];
  }

  /**
   * @dev Get number of checkpoints for `account`.
   */
  function numCheckpoints(address account) public view virtual returns (uint32) {
    return SafeCastUpgradeable.toUint32(_checkpoints[account].length);
  }

  function getVoteCount(Checkpoint storage ckpt) internal view returns (uint256 votes) {
    if (block.timestamp >= ckpt.timestamp) {
      votes = ckpt.balance;
    } else {
      votes = ckpt.votes;
    }
  }

  /**
   * @dev Get the address `account` is currently delegating to.
   */
  function delegates(address account) public view virtual override returns (address) {
    return _delegates[account];
  }

  /**
   * @dev Gets the current votes balance for `account`
   */
  function getVotes(address account) public view virtual override returns (uint256) {
    uint256 pos = _checkpoints[account].length;
    unchecked {
      return pos == 0 ? 0 : getVoteCount(_checkpoints[account][pos - 1]);
    }
  }

  /**
   * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
   *
   * Requirements:
   *
   * - `blockNumber` must have been already mined
   */
  function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
    require(blockNumber < block.number, "ERC20Votes: block not yet mined");
    return _checkpointsLookup(_checkpoints[account], blockNumber, account);
  }

  /**
   * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
   * It is NOT the sum of all the delegated votes!
   *
   * Requirements:
   *
   * - `blockNumber` must have been already mined
   */
  function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
    require(blockNumber < block.number, "ERC20Votes: block not yet mined");
    return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber, address(0));
  }

  /**
   * @dev Lookup a value in a list of (sorted) checkpoints.
   */
  function _checkpointsLookup(
    Checkpoint[] storage ckpts,
    uint256 blockNumber,
    address account
  ) internal view returns (uint256) {
    // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
    //
    // Initially we check if the block is recent to narrow the search range.
    // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
    // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
    // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
    // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
    // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
    // out of bounds (in which case we're looking too far in the past and the result is 0).
    // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
    // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
    // the same.
    uint256 length = ckpts.length;

    uint256 low = 0;
    uint256 high = length;

    if (length > 5) {
      uint256 mid = length - MathUpgradeable.sqrt(length);
      if (_unsafeAccess(ckpts, mid).fromBlock > blockNumber) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    while (low < high) {
      uint256 mid = MathUpgradeable.average(low, high);
      if (_unsafeAccess(ckpts, mid).fromBlock > blockNumber) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    unchecked {
      return high == 0 ? 0 : getVoteCount(_unsafeAccess(ckpts, high - 1));
    }
  }

  /**
   * @dev Delegate votes from the sender to `delegatee`.
   */
  function delegate(address delegatee) public virtual override {
    _delegate(_msgSender(), delegatee);
  }

  /**
   * @dev Delegates votes from signer to `delegatee`
   */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual override {
    require(block.timestamp <= expiry, "ERC20Votes: signature expired");
    address signer = ECDSAUpgradeable.recover(
      _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
      v,
      r,
      s
    );
    require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
    _delegate(signer, delegatee);
  }

  /**
   * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
   */
  function _maxSupply() internal view virtual returns (uint224) {
    return type(uint224).max;
  }

  /**
   * @dev Snapshots the totalSupply after it has been increased.
   */
  function _mint(address account, uint256 amount) internal virtual override {
    if (delegates(account) == address(0)) {
      _delegates[account] = account;
    }
    super._mint(account, amount);
    require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");
    _writeCheckpoint(_checkpoints[delegates(account)], _add, amount, balanceOf(account), false);
  }

  /**
   * @dev Snapshots the totalSupply after it has been decreased.
   */
  function _burn(address account, uint256 amount) internal virtual override {
    _writeCheckpoint(_checkpoints[delegates(account)], _subtract, amount, balanceOf(account), false);
    super._burn(account, amount);
  }

  /**
   * @dev Move voting power when tokens are transferred.
   *
   * Emits a {IVotes-DelegateVotesChanged} event.
   */
  // function _afterTokenTransfer(
  //   address from,
  //   address to,
  //   uint256 amount
  // ) internal virtual override {
  //   super._afterTokenTransfer(from, to, amount);
  //   _moveVotingPower(delegates(from), delegates(to), amount);
  // }

  /**
   * @dev Change delegation for `delegator` to `delegatee`.
   *
   * Emits events {IVotes-DelegateChanged} and {IVotes-DelegateVotesChanged}.
   */
  function _delegate(address delegator, address delegatee) internal virtual {
    address currentDelegate = delegates(delegator);
    uint256 delegatorBalance = balanceOf(delegator);
    _delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveVotingPower(
    address src,
    address dst,
    uint256 amount
  ) private {
    if (src != dst && amount > 0) {
      if (src != address(0)) {
        uint256 pos = _checkpoints[src].length;
        if (pos > 0) {
          Checkpoint memory ckpt = _unsafeAccess(_checkpoints[src], pos - 1);
          require(block.timestamp >= ckpt.timestamp, "can't delegate until holding period has passed");
        }
        (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount, amount, true);
        emit DelegateVotesChanged(src, oldWeight, newWeight);
      }

      if (dst != address(0)) {
        (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount, amount, true);
        emit DelegateVotesChanged(dst, oldWeight, newWeight);
      }
    }
  }

  function _writeCheckpoint(
    Checkpoint[] storage ckpts,
    function(uint256, uint256, uint256, uint256, uint256) view returns (uint256, uint256) op,
    uint256 delta,
    uint256 balance,
    bool preserveTimestamp
  ) private returns (uint256 oldWeight, uint256 newWeight) {
    uint256 pos = ckpts.length;

    unchecked {
      Checkpoint memory oldCkpt = pos == 0 ? Checkpoint(0, 0, 0, 0) : _unsafeAccess(ckpts, pos - 1);
      uint256 epochLength = zerofrost.epochLength();
      uint256 newBalance;
      oldWeight = oldCkpt.votes;
      (newWeight, newBalance) = op(oldWeight, delta, epochLength, oldCkpt.timestamp, balance);
      if (pos > 0 && oldCkpt.fromBlock == block.number) {
        Checkpoint storage ckpt = _unsafeAccess(ckpts, pos - 1);
        ckpt.votes = SafeCastUpgradeable.toUint224(newWeight);
        ckpt.balance = newBalance;
      } else {
        ckpts.push(
          Checkpoint(
            SafeCastUpgradeable.toUint32(block.number),
            SafeCastUpgradeable.toUint224(newWeight),
            preserveTimestamp ? oldCkpt.timestamp : block.timestamp + epochLength,
            newBalance
          )
        );
      }
    }
  }

  function _add(
    uint256 oldVotes,
    uint256 delta,
    uint256 epochLength,
    uint256 prevEpochEnd,
    uint256 balance
  ) private view returns (uint256 newVotes, uint256 newBalance) {
    uint256 prevVoteStr;
    unchecked {
      prevVoteStr = balance - delta;
    }
    if (block.timestamp >= prevEpochEnd || prevEpochEnd.sub(block.timestamp) >= epochLength) {
      newVotes = prevVoteStr;
    } else {
      newVotes = oldVotes;
    }
    newBalance = balance;
  }

  function _subtract(
    uint256 oldVotes,
    uint256 delta,
    uint256 epochLength,
    uint256 prevEpochEnd,
    uint256 balance
  ) private view returns (uint256 newVotes, uint256 newBalance) {
    if (delta == balance) return (0, 0);
    if (block.timestamp >= prevEpochEnd || prevEpochEnd.sub(block.timestamp) >= epochLength) {
      newBalance = balance - delta;
      newVotes = 0;
    } else {
      newVotes = oldVotes - delta;
      newBalance = balance - delta;
    }
  }

  function _unsafeAccess(Checkpoint[] storage ckpts, uint256 pos) private pure returns (Checkpoint storage result) {
    uint256 target = pos.mul(3);
    assembly {
      mstore(0, ckpts.slot)
      result.slot := add(keccak256(0, 0x20), target)
    }
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[47] private __gap;
}