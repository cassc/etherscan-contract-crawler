// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { SafeCastLib } from "solmate/utils/SafeCastLib.sol";

import { IFlywheelRewards } from "flywheel/interfaces/IFlywheelRewards.sol";
import { IFlywheelBooster } from "flywheel/interfaces/IFlywheelBooster.sol";

import { SafeOwnableUpgradeable } from "../../../midas/SafeOwnableUpgradeable.sol";

contract MidasFlywheelCore is SafeOwnableUpgradeable {
  using SafeTransferLib for ERC20;
  using SafeCastLib for uint256;

  /// @notice How much rewardsToken will be send to treasury
  uint256 public performanceFee;

  /// @notice Address that gets rewardsToken accrued by performanceFee
  address public feeRecipient;

  /// @notice The token to reward
  ERC20 public rewardToken;

  /// @notice append-only list of strategies added
  ERC20[] public allStrategies;

  /// @notice the rewards contract for managing streams
  IFlywheelRewards public flywheelRewards;

  /// @notice optional booster module for calculating virtual balances on strategies
  IFlywheelBooster public flywheelBooster;

  /// @notice The accrued but not yet transferred rewards for each user
  mapping(address => uint256) public rewardsAccrued;

  /// @notice The strategy index and last updated per strategy
  mapping(ERC20 => RewardsState) public strategyState;

  /// @notice user index per strategy
  mapping(ERC20 => mapping(address => uint224)) public userIndex;

  function initialize(
    ERC20 _rewardToken,
    IFlywheelRewards _flywheelRewards,
    IFlywheelBooster _flywheelBooster,
    address _owner
  ) public initializer {
    __SafeOwnable_init();

    rewardToken = _rewardToken;
    flywheelRewards = _flywheelRewards;
    flywheelBooster = _flywheelBooster;

    _transferOwnership(_owner);

    performanceFee = 10e16; // 10%
    feeRecipient = _owner;
  }

  /*///////////////////////////////////////////////////////////////
                        ACCRUE/CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

  /** 
      @notice Emitted when a user's rewards accrue to a given strategy.
      @param strategy the updated rewards strategy
      @param user the user of the rewards
      @param rewardsDelta how many new rewards accrued to the user
      @param rewardsIndex the market index for rewards per token accrued
    */
  event AccrueRewards(ERC20 indexed strategy, address indexed user, uint256 rewardsDelta, uint256 rewardsIndex);

  /** 
      @notice Emitted when a user claims accrued rewards.
      @param user the user of the rewards
      @param amount the amount of rewards claimed
    */
  event ClaimRewards(address indexed user, uint256 amount);

  /** 
      @notice accrue rewards for a single user on a strategy
      @param strategy the strategy to accrue a user's rewards on
      @param user the user to be accrued
      @return the cumulative amount of rewards accrued to user (including prior)
    */
  function accrue(ERC20 strategy, address user) public returns (uint256) {
    RewardsState memory state = strategyState[strategy];

    if (state.index == 0) return 0;

    state = accrueStrategy(strategy, state);
    return accrueUser(strategy, user, state);
  }

  /** 
      @notice accrue rewards for a two users on a strategy
      @param strategy the strategy to accrue a user's rewards on
      @param user the first user to be accrued
      @param user the second user to be accrued
      @return the cumulative amount of rewards accrued to the first user (including prior)
      @return the cumulative amount of rewards accrued to the second user (including prior)
    */
  function accrue(
    ERC20 strategy,
    address user,
    address secondUser
  ) public returns (uint256, uint256) {
    RewardsState memory state = strategyState[strategy];

    if (state.index == 0) return (0, 0);

    state = accrueStrategy(strategy, state);
    return (accrueUser(strategy, user, state), accrueUser(strategy, secondUser, state));
  }

  /** 
      @notice claim rewards for a given user
      @param user the user claiming rewards
      @dev this function is public, and all rewards transfer to the user
    */
  function claimRewards(address user) external {
    uint256 accrued = rewardsAccrued[user];

    if (accrued != 0) {
      rewardsAccrued[user] = 0;

      rewardToken.safeTransferFrom(address(flywheelRewards), user, accrued);

      emit ClaimRewards(user, accrued);
    }
  }

  /*///////////////////////////////////////////////////////////////
                          ADMIN LOGIC
    //////////////////////////////////////////////////////////////*/

  /** 
      @notice Emitted when a new strategy is added to flywheel by the admin
      @param newStrategy the new added strategy
    */
  event AddStrategy(address indexed newStrategy);

  /// @notice initialize a new strategy
  function addStrategyForRewards(ERC20 strategy) external onlyOwner {
    _addStrategyForRewards(strategy);
  }

  function _addStrategyForRewards(ERC20 strategy) internal {
    require(strategyState[strategy].index == 0, "strategy");
    strategyState[strategy] = RewardsState({
      index: (10**rewardToken.decimals()).safeCastTo224(),
      lastUpdatedTimestamp: block.timestamp.safeCastTo32()
    });

    allStrategies.push(strategy);
    emit AddStrategy(address(strategy));
  }

  function getAllStrategies() external view returns (ERC20[] memory) {
    return allStrategies;
  }

  /** 
      @notice Emitted when the rewards module changes
      @param newFlywheelRewards the new rewards module
    */
  event FlywheelRewardsUpdate(address indexed newFlywheelRewards);

  /// @notice swap out the flywheel rewards contract
  function setFlywheelRewards(IFlywheelRewards newFlywheelRewards) external onlyOwner {
    if (address(flywheelRewards) != address(0)) {
      uint256 oldRewardBalance = rewardToken.balanceOf(address(flywheelRewards));
      if (oldRewardBalance > 0) {
        rewardToken.safeTransferFrom(address(flywheelRewards), address(newFlywheelRewards), oldRewardBalance);
      }
    }

    flywheelRewards = newFlywheelRewards;

    emit FlywheelRewardsUpdate(address(newFlywheelRewards));
  }

  /** 
      @notice Emitted when the booster module changes
      @param newBooster the new booster module
    */
  event FlywheelBoosterUpdate(address indexed newBooster);

  /// @notice swap out the flywheel booster contract
  function setBooster(IFlywheelBooster newBooster) external onlyOwner {
    flywheelBooster = newBooster;

    emit FlywheelBoosterUpdate(address(newBooster));
  }

  event UpdatedFeeSettings(
    uint256 oldPerformanceFee,
    uint256 newPerformanceFee,
    address oldFeeRecipient,
    address newFeeRecipient
  );

  /**
   * @notice Update performanceFee and/or feeRecipient
   * @dev Claim rewards first from the previous feeRecipient before changing it
   */
  function updateFeeSettings(uint256 _performanceFee, address _feeRecipient) external onlyOwner {
    _updateFeeSettings(_performanceFee, _feeRecipient);
  }

  function _updateFeeSettings(uint256 _performanceFee, address _feeRecipient) internal {
    emit UpdatedFeeSettings(performanceFee, _performanceFee, feeRecipient, _feeRecipient);

    if (feeRecipient != _feeRecipient) {
      rewardsAccrued[_feeRecipient] += rewardsAccrued[feeRecipient];
      rewardsAccrued[feeRecipient] = 0;
    }
    performanceFee = _performanceFee;
    feeRecipient = _feeRecipient;
  }

  /*///////////////////////////////////////////////////////////////
                    INTERNAL ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

  struct RewardsState {
    /// @notice The strategy's last updated index
    uint224 index;
    /// @notice The timestamp the index was last updated at
    uint32 lastUpdatedTimestamp;
  }

  /// @notice accumulate global rewards on a strategy
  function accrueStrategy(ERC20 strategy, RewardsState memory state)
    private
    returns (RewardsState memory rewardsState)
  {
    // calculate accrued rewards through module
    uint256 strategyRewardsAccrued = flywheelRewards.getAccruedRewards(strategy, state.lastUpdatedTimestamp);

    rewardsState = state;

    if (strategyRewardsAccrued > 0) {
      // use the booster or token supply to calculate reward index denominator
      uint256 supplyTokens = address(flywheelBooster) != address(0)
        ? flywheelBooster.boostedTotalSupply(strategy)
        : strategy.totalSupply();

      // 100% = 100e16
      uint256 accruedFees = (strategyRewardsAccrued * performanceFee) / uint224(100e16);

      rewardsAccrued[feeRecipient] += accruedFees;
      strategyRewardsAccrued -= accruedFees;

      uint224 deltaIndex;

      if (supplyTokens != 0)
        deltaIndex = ((strategyRewardsAccrued * (10**strategy.decimals())) / supplyTokens).safeCastTo224();

      // accumulate rewards per token onto the index, multiplied by fixed-point factor
      rewardsState = RewardsState({
        index: state.index + deltaIndex,
        lastUpdatedTimestamp: block.timestamp.safeCastTo32()
      });
      strategyState[strategy] = rewardsState;
    }
  }

  /// @notice accumulate rewards on a strategy for a specific user
  function accrueUser(
    ERC20 strategy,
    address user,
    RewardsState memory state
  ) private returns (uint256) {
    // load indices
    uint224 strategyIndex = state.index;
    uint224 supplierIndex = userIndex[strategy][user];

    // sync user index to global
    userIndex[strategy][user] = strategyIndex;

    // if user hasn't yet accrued rewards, grant them interest from the strategy beginning if they have a balance
    // zero balances will have no effect other than syncing to global index
    if (supplierIndex == 0) {
      supplierIndex = (10**rewardToken.decimals()).safeCastTo224();
    }

    uint224 deltaIndex = strategyIndex - supplierIndex;
    // use the booster or token balance to calculate reward balance multiplier
    uint256 supplierTokens = address(flywheelBooster) != address(0)
      ? flywheelBooster.boostedBalanceOf(strategy, user)
      : strategy.balanceOf(user);

    // accumulate rewards by multiplying user tokens by rewardsPerToken index and adding on unclaimed
    uint256 supplierDelta = (deltaIndex * supplierTokens) / (10**strategy.decimals());
    uint256 supplierAccrued = rewardsAccrued[user] + supplierDelta;

    rewardsAccrued[user] = supplierAccrued;

    emit AccrueRewards(strategy, user, supplierDelta, strategyIndex);

    return supplierAccrued;
  }
}