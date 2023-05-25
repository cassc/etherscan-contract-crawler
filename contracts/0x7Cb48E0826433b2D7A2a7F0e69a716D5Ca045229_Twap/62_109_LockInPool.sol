// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../BasePool.sol";

/**
 * Integrates a timelock of `LOCK_DURATION` on the Pool.
 * Can only withdraw from the pool if:
 * - not started
 * - or requested an unlock and waited the `LOCK_DURATION`
 * - or the rewards have finished for `REFILL_ALLOWANCE`.
 */
abstract contract LockInPool is BasePool {
  using SafeMath for uint256;

  uint256 private constant REFILL_ALLOWANCE = 2 hours;
  uint256 private constant LOCK_DURATION = 8 days;

  mapping(address => uint256) public unlocks;
  uint256 private _unlockingSupply;

  event Unlock(address indexed account);

  /* ========== VIEWS ========== */

  /**
   * @notice The balance that is currently being unlocked
   * @param account The account we're interested in.
   */
  function inLimbo(address account) public view returns (uint256) {
    if (unlocks[account] == 0) {
      return 0;
    }
    return super.balanceOf(account);
  }

  /// @inheritdoc BasePool
  function balanceOf(address account)
    public
    view
    virtual
    override(BasePool)
    returns (uint256)
  {
    if (unlocks[account] != 0) {
      return 0;
    }
    return super.balanceOf(account);
  }

  /// @inheritdoc BasePool
  function totalSupply()
    public
    view
    virtual
    override(BasePool)
    returns (uint256)
  {
    return super.totalSupply().sub(_unlockingSupply);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Request unlock of the token, removing this senders reward accural by:
   * - Setting balanceOf to return 0 (used for reward calculation) and adjusting total supply by amount unlocking.
   */
  function unlock() external updateReward(msg.sender) {
    require(unlocks[msg.sender] == 0, "LockIn/UnlockOnce");

    _unlockingSupply = _unlockingSupply.add(balanceOf(msg.sender));
    unlocks[msg.sender] = block.timestamp;

    emit Unlock(msg.sender);
  }

  /* ========== HOOKS ========== */

  /**
   * @notice Handle unlocks when staking, resets lock if was unlocking
   */
  function _beforeStake(
    address staker,
    address recipient,
    uint256 amount
  ) internal virtual override(BasePool) {
    super._beforeStake(staker, recipient, amount);

    if (unlocks[recipient] != 0) {
      // If we are resetting an unlock, reset the unlockingSupply
      _unlockingSupply = _unlockingSupply.sub(inLimbo(recipient));
      unlocks[recipient] = 0;
    }
  }

  /**
   * @dev Prevent withdrawal if:
   * - has started (i.e. rewards have entered the pool)
   * - before finished (+ allowance)
   * - not unlocked `LOCK_DURATION` ago
   *
   * - reset the unlock, so you can re-enter.
   */
  function _beforeWithdraw(address recipient, uint256 amount)
    internal
    virtual
    override(BasePool)
  {
    super._beforeWithdraw(recipient, amount);

    // Before rewards have been added / after + `REFILL`
    bool releaseWithoutLock =
      block.timestamp >= periodFinish.add(REFILL_ALLOWANCE);

    // A lock has been requested and the `LOCK_DURATION` has passed.
    bool releaseWithLock =
      (unlocks[recipient] != 0) &&
        (unlocks[recipient] <= block.timestamp.sub(LOCK_DURATION));

    require(releaseWithoutLock || releaseWithLock, "LockIn/NotReleased");

    if (unlocks[recipient] != 0) {
      // Reduce unlocking supply (so we don't keep discounting total supply when
      // it is reduced). Amount will be validated in withdraw proper.
      _unlockingSupply = _unlockingSupply.sub(amount);
    }
  }
}