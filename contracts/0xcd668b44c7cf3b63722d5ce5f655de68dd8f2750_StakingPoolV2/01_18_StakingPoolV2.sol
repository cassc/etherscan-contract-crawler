// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import './logic/StakingPoolLogicV2.sol';
import './interface/IStakingPoolV2.sol';
import './token/StakedElyfiToken.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Elyfi StakingPool contract
/// @notice Users can stake their asset and earn reward for their staking.
/// The reward calculation is based on the reward index and user balance. The amount of reward index change
/// is inversely proportional to the total amount of supply. Accrued rewards can be obtained by multiplying
/// the difference between the user index and the current index by the user balance. User index and the pool
/// index is updated and aligned with in the staking and withdrawing action.
/// @author Elysia
contract StakingPoolV2 is IStakingPoolV2, StakedElyfiToken {
  using StakingPoolLogicV2 for PoolData;

  constructor(IERC20 stakingAsset_, IERC20 rewardAsset_) StakedElyfiToken(stakingAsset_) {
    stakingAsset = stakingAsset_;
    rewardAsset = rewardAsset_;
    _admin = msg.sender;
  }

  struct PoolData {
    uint256 rewardPerSecond;
    uint256 rewardIndex;
    uint256 startTimestamp;
    uint256 endTimestamp;
    uint256 totalPrincipal;
    uint256 lastUpdateTimestamp;
    mapping(address => uint256) userIndex;
    mapping(address => uint256) userReward;
    mapping(address => uint256) userPrincipal;
  }

  uint8 public currentRound;

  address internal _admin;

  IERC20 public stakingAsset;
  IERC20 public rewardAsset;

  mapping(uint8 => PoolData) internal _rounds;

  /***************** View functions ******************/

  /// @notice Returns reward index of the round
  /// @param round The round of the pool
  function getRewardIndex(uint8 round) external view override returns (uint256) {
    PoolData storage poolData = _rounds[round];
    return poolData.getRewardIndex();
  }

  /// @notice Returns user accrued reward index of the round
  /// @param user The user address
  /// @param round The round of the pool
  function getUserReward(address user, uint8 round) external view override returns (uint256) {
    PoolData storage poolData = _rounds[round];
    return poolData.getUserReward(user);
  }

  /// @notice Returns the state and data of the round
  /// @param round The round of the pool
  /// @return rewardPerSecond The total reward accrued per second in the round
  /// @return rewardIndex The reward index of the round
  /// @return startTimestamp The start timestamp of the round
  /// @return endTimestamp The end timestamp of the round
  /// @return totalPrincipal The total staked amount of the round
  /// @return lastUpdateTimestamp The last update timestamp of the round
  function getPoolData(uint8 round)
    external
    view
    override
    returns (
      uint256 rewardPerSecond,
      uint256 rewardIndex,
      uint256 startTimestamp,
      uint256 endTimestamp,
      uint256 totalPrincipal,
      uint256 lastUpdateTimestamp
    )
  {
    PoolData storage poolData = _rounds[round];
    return (
      poolData.rewardPerSecond,
      poolData.rewardIndex,
      poolData.startTimestamp,
      poolData.endTimestamp,
      poolData.totalPrincipal,
      poolData.lastUpdateTimestamp
    );
  }

  /// @notice Returns the state and data of the user
  /// @param round The round of the pool
  /// @param user The user address
  function getUserData(uint8 round, address user)
    external
    view
    override
    returns (
      uint256 userIndex,
      uint256 userReward,
      uint256 userPrincipal
    )
  {
    PoolData storage poolData = _rounds[round];

    return (poolData.userIndex[user], poolData.userReward[user], poolData.userPrincipal[user]);
  }

  /***************** External functions ******************/

  /// @notice Stake the amount of staking asset to pool contract and update data.
  /// @param amount Amount to stake.
  function stake(uint256 amount) external override {
    PoolData storage poolData = _rounds[currentRound];

    if (currentRound == 0) revert StakingNotInitiated();
    if (poolData.endTimestamp < block.timestamp || poolData.startTimestamp > block.timestamp)
      revert NotInRound();
    if (amount == 0) revert InvaidAmount();

    poolData.updateStakingPool(currentRound, msg.sender);

    _depositFor(msg.sender, amount);

    poolData.userPrincipal[msg.sender] += amount;
    poolData.totalPrincipal += amount;

    emit Stake(
      msg.sender,
      amount,
      poolData.userIndex[msg.sender],
      poolData.userPrincipal[msg.sender],
      currentRound
    );
  }

  /// @notice Withdraw the amount of principal from the pool contract and update data
  /// @param amount Amount to withdraw
  /// @param round The round to withdraw
  function withdraw(uint256 amount, uint8 round) external override {
    _withdraw(amount, round);
  }

  /// @notice Transfer accrued reward to msg.sender. User accrued reward will be reset and user reward index will be set to the current reward index.
  /// @param round The round to claim
  function claim(uint8 round) external override {
    _claim(msg.sender, round);
  }

  /// @notice Migrate the amount of principal to the current round and transfer the rest principal to the caller
  /// @param amount Amount to migrate.
  /// @param round The closed round to migrate
  function migrate(uint256 amount, uint8 round) external override {
    if (round >= currentRound) revert NotInitiatedRound(round, currentRound);
    PoolData storage poolData = _rounds[round];
    uint256 userPrincipal = poolData.userPrincipal[msg.sender];

    if (userPrincipal == 0) revert ZeroPrincipal();

    uint256 amountToWithdraw = userPrincipal - amount;

    // Claim reward
    if (poolData.getUserReward(msg.sender) != 0) {
      _claim(msg.sender, round);
    }

    // Withdraw
    if (amountToWithdraw != 0) {
      _withdraw(amountToWithdraw, round);
    }

    // Update current pool
    PoolData storage currentPoolData = _rounds[currentRound];
    currentPoolData.updateStakingPool(currentRound, msg.sender);

    // Migrate user principal
    poolData.userPrincipal[msg.sender] -= amount;
    currentPoolData.userPrincipal[msg.sender] += amount;

    // Migrate total principal
    poolData.totalPrincipal -= amount;
    currentPoolData.totalPrincipal += amount;

    emit Stake(
      msg.sender,
      amount,
      currentPoolData.userIndex[msg.sender],
      currentPoolData.userPrincipal[msg.sender],
      currentRound
    );

    emit Migrate(msg.sender, amount, round, currentRound);
  }

  /***************** Internal Functions ******************/

  function _withdraw(uint256 amount, uint8 round) internal {
    PoolData storage poolData = _rounds[round];
    uint256 amountToWithdraw = amount;

    if (round > currentRound) revert NotInitiatedRound(round, currentRound);
    if (amount == type(uint256).max) {
      amountToWithdraw = poolData.userPrincipal[msg.sender];
    }
    if (poolData.userPrincipal[msg.sender] < amountToWithdraw)
      revert NotEnoughPrincipal(poolData.userPrincipal[msg.sender]);

    poolData.updateStakingPool(round, msg.sender);

    poolData.userPrincipal[msg.sender] -= amountToWithdraw;
    poolData.totalPrincipal -= amountToWithdraw;

    _withdrawTo(msg.sender, amountToWithdraw);

    emit Withdraw(
      msg.sender,
      amountToWithdraw,
      poolData.userIndex[msg.sender],
      poolData.userPrincipal[msg.sender],
      currentRound
    );
  }

  function _claim(address user, uint8 round) internal {
    if (round > currentRound) revert NotInitiatedRound(round, currentRound);

    PoolData storage poolData = _rounds[round];

    uint256 reward = poolData.getUserReward(user);

    if (reward == 0) revert ZeroReward();

    poolData.userReward[user] = 0;
    poolData.userIndex[user] = poolData.getRewardIndex();

    SafeERC20.safeTransfer(rewardAsset, user, reward);

    uint256 rewardLeft = rewardAsset.balanceOf(address(this));

    emit Claim(user, reward, rewardLeft, round);
  }

  /***************** Admin Functions ******************/

  /// @notice Init the new round. After the round closed, staking is not allowed.
  /// @param rewardPerSecond The total accrued reward per second in new round
  /// @param startTimestamp The start timestamp of initiated round
  /// @param duration The duration of the initiated round
  function initNewRound(
    uint256 rewardPerSecond,
    uint256 startTimestamp,
    uint256 duration
  ) external override onlyAdmin {
    PoolData storage poolDataBefore = _rounds[currentRound];

    uint256 roundstartTimestamp = startTimestamp;

    if (roundstartTimestamp < poolDataBefore.endTimestamp) revert RoundConflicted();

    uint8 newRound = currentRound + 1;

    (uint256 newRoundStartTimestamp, uint256 newRoundEndTimestamp) = _rounds[newRound].initRound(
      rewardPerSecond,
      startTimestamp,
      duration
    );

    currentRound = newRound;

    emit InitRound(rewardPerSecond, newRoundStartTimestamp, newRoundEndTimestamp, currentRound);
  }

  function retrieveResidue() external onlyAdmin {
    SafeERC20.safeTransfer(rewardAsset, _admin, rewardAsset.balanceOf(address(this)));
  }

  /***************** Modifier ******************/

  modifier onlyAdmin() {
    if (msg.sender != _admin) revert OnlyAdmin();
    _;
  }
}