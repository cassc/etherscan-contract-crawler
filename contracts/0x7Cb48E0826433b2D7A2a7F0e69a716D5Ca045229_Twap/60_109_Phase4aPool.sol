// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./BasePool.sol";
import "./extensions/DeadlinePool.sol";

import "./extensions/LockInPool.sol";

/**
 * Phase 4a Pool - is a special ceremony pool that can only be joined within the window period and has a Lock in period for the tokens
 */
contract Phase4aPool is DeadlinePool, LockInPool {
  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new BasePool
   * @param _admin The default role controller
   * @param _rewardDistribution The reward distributor (can change reward rate)
   * @param _rewardToken The reward token to distribute
   * @param _stakingToken The staking token used to qualify for rewards
   * @param _startWindow When ceremony starts
   * @param _endWindow When ceremony ends
   */
  constructor(
    address _admin,
    address _rewardDistribution,
    address _rewardToken,
    address _stakingToken,
    uint256 _duration,
    uint256 _startWindow,
    uint256 _endWindow
  )
    DeadlinePool(
      _admin,
      _rewardDistribution,
      _rewardToken,
      _stakingToken,
      _duration,
      _startWindow,
      _endWindow
    )
  {}

  // COMPILER HINTS for overrides

  function _beforeStake(
    address staker,
    address recipient,
    uint256 amount
  ) internal virtual override(LockInPool, DeadlinePool) {
    super._beforeStake(staker, recipient, amount);
  }

  function _beforeWithdraw(address from, uint256 amount)
    internal
    virtual
    override(BasePool, LockInPool)
  {
    super._beforeWithdraw(from, amount);
  }

  function balanceOf(address account)
    public
    view
    virtual
    override(BasePool, LockInPool)
    returns (uint256)
  {
    return super.balanceOf(account);
  }

  function totalSupply()
    public
    view
    virtual
    override(BasePool, LockInPool)
    returns (uint256)
  {
    return super.totalSupply();
  }
}