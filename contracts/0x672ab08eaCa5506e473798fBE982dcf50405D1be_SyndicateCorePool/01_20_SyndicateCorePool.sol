// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./SyndicatePoolBase.sol";

/**
 * @title Syndicate Core Pool
 *        Original title: Illuvium Core Pool
 *
 * @notice Core pools represent permanent pools like SYNR or SYNR/ETH Pair pool,
 *      core pools allow staking for arbitrary periods of time up to 1 year
 *
 * @dev See SyndicatePoolBase for more details
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 * Adapted for Syn City by Superpower Labs
 */
contract SyndicateCorePool is SyndicatePoolBase {
  /// @dev Flag indicating pool type, false means "core pool"
  // solhint-disable-next-line
  bool public constant override isFlashPool = false;

  /// @dev Control parameter of how much reward in sSYNR user will get immediately upon staking.
  /// 0 when feature is disabled.  In base points.
  uint256 public quickRewardRate;

  uint256 public totalQuickReward;

  uint256 public maxQuickReward;

  /// @dev Link to deployed SyndicateVault instance
  address public vault;

  /// @dev Used to calculate vault rewards
  /// @dev This value is different from "reward per token" used in locked pool
  /// @dev Note: stakes are different in duration and "weight" reflects that
  uint256 public vaultRewardsPerWeight;

  /// @dev Pool tokens value available in the pool;
  ///      pool token examples are SYNR (SYNR core pool) or SYNR/ETH pair (LP core pool)
  /// @dev For LP core pool this value doesnt' count for SYNR tokens received as Vault rewards
  ///      while for SYNR core pool it does count for such tokens as well
  uint256 public poolTokenReserve;

  /**
   * @dev Fired in receiveVaultRewards()
   *
   * @param _by an address that sent the rewards, always a vault
   * @param amount amount of tokens received
   */
  event VaultRewardsReceived(address indexed _by, uint256 amount);

  /**
   * @dev Fired in _processVaultRewards() and dependent functions, like processRewards()
   *
   * @param _by an address which executed the function
   * @param _to an address which received a reward
   * @param amount amount of reward received
   */
  event VaultRewardsClaimed(address indexed _by, address indexed _to, uint256 amount);

  /**
   * @dev Fired in setVault()
   *
   * @param _by an address which executed the function, always a factory owner
   */
  event VaultUpdated(address indexed _by, address _fromVal, address _toVal);

  /**
   * @dev Creates/deploys an instance of the core pool
   *
   * @param _synr SYNR ERC20 Token SyndicateERC20 address
   * @param _ssynr sSYNR ERC20 Token  SyntheticSyndicateERC20 address
   * @param _factory Pool factory SyndicatePoolFactory instance/address
   * @param _poolToken token the pool operates on, for example SYNR or SYNR/ETH pair
   * @param _initBlock initial block used to calculate the rewards
   * @param _weight number representing a weight of the pool, actual weight fraction
   *      is calculated as that number divided by the total pools weight and doesn't exceed one
   */
  constructor(
    address _synr,
    address _ssynr,
    SyndicatePoolFactory _factory,
    address _poolToken,
    uint64 _initBlock,
    uint32 _weight
  ) SyndicatePoolBase(_synr, _ssynr, _factory, _poolToken, _initBlock, _weight) {}

  /**
   * @notice Calculates current vault rewards value available for address specified
   *
   * @dev Performs calculations based on current smart contract state only,
   *      not taking into account any additional time/blocks which might have passed
   *
   * @param _staker an address to calculate vault rewards value for
   * @return pending calculated vault reward value for the given address
   */
  function pendingVaultRewards(address _staker) public view returns (uint256 pending) {
    User storage user = users[_staker];

    return weightToReward(user.totalWeight, vaultRewardsPerWeight) - user.subVaultRewards;
  }

  /** @notice set the reward weight for sSYNR distributed upon staking
   *
   *  @dev  divide quick reward by 10000 to get the actual value and 100000 (10x) is used as a general limit
   *
   *  @param _quickRewardRate the reward rate in base point
   */
  function setQuickRewardRate(uint256 _quickRewardRate) external onlyFactoryOwner {
    // the is a general limit, should not exceed 10x
    require(_quickRewardRate < 100000, "parameter out of range");
    quickRewardRate = _quickRewardRate;
  }

  function setMaxQuickReward(uint256 _maxQuickReward) external onlyFactoryOwner {
    maxQuickReward = _maxQuickReward;
  }

  /**
   * @dev Executed only by the factory owner to Set the vault
   *
   * @param _vault an address of deployed SyndicateVault instance
   */
  function setVault(address _vault) external {
    // verify function is executed by the factory owner
    require(factory.owner() == msg.sender, "access denied");

    // verify input is set
    require(_vault != address(0), "zero input");

    // emit an event
    emit VaultUpdated(msg.sender, vault, _vault);

    // update vault address
    vault = _vault;
  }

  /**
   * @dev Executed by the vault to transfer vault rewards SYNR from the vault
   *      into the pool
   *
   * @dev This function is executed only for SYNR core pools
   *
   * @param _rewardsAmount amount of SYNR rewards to transfer into the pool
   */
  function receiveVaultRewards(uint256 _rewardsAmount) external {
    require(msg.sender == vault, "access denied");
    // return silently if there is no reward to receive
    if (_rewardsAmount == 0) {
      return;
    }
    require(usersLockingWeight > 0, "zero locking weight");

    _transferSynFrom(msg.sender, address(this), _rewardsAmount);

    vaultRewardsPerWeight += rewardToWeight(_rewardsAmount, usersLockingWeight);

    // update `poolTokenReserve` only if this is a SYNR Core Pool
    if (poolToken == synr) {
      poolTokenReserve += _rewardsAmount;
    }

    emit VaultRewardsReceived(msg.sender, _rewardsAmount);
  }

  /**
   * @notice Service function to calculate and pay pending vault and yield rewards to the sender
   *
   * @dev Internally executes similar function `_processRewards` from the parent smart contract
   *      to calculate and pay yield rewards; adds vault rewards processing
   *
   * @dev Can be executed by anyone at any time, but has an effect only when
   *      executed by deposit holder and when at least one block passes from the
   *      previous reward processing
   * @dev Executed internally when "staking as a pool" (`stakeAsPool`)
   * @dev When timing conditions are not met (executed too frequently, or after factory
   *      end block), function doesn't throw and exits silently
   *
   * @dev _useSSYN flag has a context of yield rewards only
   *
   * @param _useSSYN flag indicating whether to mint sSYNR token as a reward or not;
   *      when set to true - sSYNR reward is minted immediately and sent to sender,
   *      when set to false - new SYNR reward deposit gets created if pool is an SYNR pool
   *      (poolToken is SYNR token), or new pool deposit gets created together with sSYNR minted
   *      when pool is not an SYNR pool (poolToken is not an SYNR token)
   */
  function processRewards(bool _useSSYN) external override poolAlive {
    _processRewards(msg.sender, _useSSYN, true);
  }

  /**
   * @dev Executed internally by the pool itself (from the parent `SyndicatePoolBase` smart contract)
   *      as part of yield rewards processing logic (`SyndicatePoolBase._processRewards` function)
   * @dev Executed when _useSSYN is false and pool is not an SYNR pool - see `SyndicatePoolBase._processRewards`
   *
   * @param _staker an address which stakes (the yield reward)
   * @param _amount amount to be staked (yield reward amount)
   */
  function stakeAsPool(address _staker, uint256 _amount) external {
    require(factory.poolExists(msg.sender), "access denied");
    _sync();
    User storage user = users[_staker];
    if (user.tokenAmount > 0) {
      _processRewards(_staker, false, false);
    }
    uint256 depositWeight = _amount * YEAR_STAKE_WEIGHT_MULTIPLIER;
    Deposit memory newDeposit = Deposit({
      tokenAmount: _amount,
      lockedFrom: uint64(now256()),
      lockedUntil: uint64(now256() + 365 days),
      weight: depositWeight,
      isYield: true
    });
    user.tokenAmount += _amount;
    user.totalWeight += depositWeight;
    user.deposits.push(newDeposit);

    usersLockingWeight += depositWeight;

    user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
    user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);

    // update `poolTokenReserve` only if this is a LP Core Pool (stakeAsPool can be executed only for LP pool)
    poolTokenReserve += _amount;
  }

  /**
   * @inheritdoc SyndicatePoolBase
   *
   * @dev Extends base functionality and updates vault rewards checkpoint
   */
  function _updateStakeLock(
    address _staker,
    uint256 _depositId,
    uint64 _lockedUntil,
    bool _useSSYN
  ) internal override poolAlive {
    super._updateStakeLock(_staker, _depositId, _lockedUntil, _useSSYN);
    User storage user = users[_staker];
    // updates sub vault rewards value
    user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);
  }

  /**
   * @inheritdoc SyndicatePoolBase
   *
   * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
   *      and updates (increases) pool token reserve (pool tokens value available in the pool)
   */
  function _stake(
    address _staker,
    uint256 _amount,
    uint64 _lockedUntil,
    bool _useSSYN,
    bool _isYield
  ) internal override {
    super._stake(_staker, _amount, _lockedUntil, _useSSYN, _isYield);
    User storage user = users[_staker];
    user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);

    poolTokenReserve += _amount;

    // distribute quick reward, additional checks on _lockedUntil is done in super._stake
    if (quickRewardRate > 0 && _lockedUntil > 0) {
      uint256 reward = ((_lockedUntil - now256()) * _amount * quickRewardRate) / (10000 * 365 days);
      if (totalQuickReward < maxQuickReward) {
        if (totalQuickReward + reward > maxQuickReward) {
          reward = maxQuickReward - totalQuickReward;
        }
        mintSSyn(_staker, reward);
        totalQuickReward += reward;
      }
    }
  }

  /**
   * @inheritdoc SyndicatePoolBase
   *
   * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
   *      and updates (decreases) pool token reserve (pool tokens value available in the pool)
   */
  function _unstake(
    address _staker,
    uint256 _depositId,
    uint256 _amount,
    bool _useSSYN
  ) internal override {
    User storage user = users[_staker];
    Deposit memory stakeDeposit = user.deposits[_depositId];
    require(stakeDeposit.lockedFrom == 0 || now256() > stakeDeposit.lockedUntil, "deposit not yet unlocked");
    poolTokenReserve -= _amount;
    super._unstake(_staker, _depositId, _amount, _useSSYN);
    user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);
  }

  /**
   * @inheritdoc SyndicatePoolBase
   *
   * @dev Additionally to the parent smart contract, processes vault rewards of the holder,
   *      and for SYNR pool updates (increases) pool token reserve (pool tokens value available in the pool)
   */
  function _processRewards(
    address _staker,
    bool _useSSYN,
    bool _withUpdate
  ) internal override returns (uint256 pendingYield) {
    _processVaultRewards(_staker, _withUpdate);
    pendingYield = super._processRewards(_staker, _useSSYN, _withUpdate);

    // update `poolTokenReserve` only if this is a SYNR Core Pool
    if (poolToken == synr && !_useSSYN) {
      poolTokenReserve += pendingYield;
    }
  }

  /**
   * @dev Used internally to process vault rewards for the staker
   *
   * @param _staker address of the user (staker) to process rewards for
   */
  function _processVaultRewards(address _staker, bool _withUpdate) private {
    User storage user = users[_staker];
    uint256 pendingVaultClaim = pendingVaultRewards(_staker);
    if (pendingVaultClaim == 0) return;
    // read SYNR token balance of the pool via standard ERC20 interface
    uint256 synBalance = IERC20(synr).balanceOf(address(this));
    require(synBalance >= pendingVaultClaim, "contract SYNR balance too low");

    // update `poolTokenReserve` only if this is a SYNR Core Pool
    if (poolToken == synr) {
      // protects against rounding errors
      poolTokenReserve -= pendingVaultClaim > poolTokenReserve ? poolTokenReserve : pendingVaultClaim;
    }

    if (_withUpdate) {
      user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);
    }

    // transfer fails if pool SYNR balance is not enough - which is a desired behavior
    _transferSyn(_staker, pendingVaultClaim);

    emit VaultRewardsClaimed(msg.sender, _staker, pendingVaultClaim);
  }

  function delegate(address receiver) external onlyFactoryOwner {
    require(poolToken == synr, "CorePool: only synr pool can delegate");
    SyndicateERC20(synr).delegate(receiver);
  }
}