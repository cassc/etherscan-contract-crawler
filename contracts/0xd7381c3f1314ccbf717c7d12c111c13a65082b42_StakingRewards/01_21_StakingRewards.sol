// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import { IDepositToken, IBALRewardPool, AssetData } from "./interfaces/interfaces.sol";
import { IBalancerMinter } from "./interfaces/IBalancerMinter.sol";
import { IBalancerGauge } from "./interfaces/IBalancerGauge.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { DepositToken } from "./DepositToken.sol";
import { BALRewardPool } from "./BALRewardPool.sol";

/**
 * @title StakingRewards
 * @author Planetarium
 * @notice Contract to stake WNCG BPT and rewards WNCG
 */
contract StakingRewards is Initializable {
  using SafeMath for uint128;
  using SafeMath for uint256;  
  using SafeERC20Upgradeable for IERC20Upgradeable;
  
  /// @notice Token to stake (LP Token)
  IERC20Upgradeable public STAKED_TOKEN;

  /// @notice Token for rewards (WNCG)
  IERC20Upgradeable public REWARD_TOKEN;
      
  /// @notice Seconds for cooldown period
  uint128 public COOLDOWN_SECONDS;

  /// @notice Seconds available to redeem onece the cooldown period is fullfilled
  uint128 public UNSTAKE_WINDOW;

  /// @notice Address to pull the rewards for this contract
  address public REWARDS_VAULT;

  /// @notice Address for bal operation
  address public BAL_OPERATION_VAULT;

  uint128 private constant THREE_DAYS = 3 days;
  uint128 private constant TWO_WEEKS = 14 days;
  uint8 private constant PRECISION = 18;

  /// @notice Rewards to claim for each accounts
  mapping(address => uint256) public rewardsToClaim;  

  /// @notice Cooldowns for each accounts
  mapping(address => uint256) public cooldowns;

  /// @dev Balances for each accounts
  mapping(address => uint256) private balances;

  /// @dev Total Staked Amount
  uint private totalSupply;

  /// @dev Asset Data
  AssetData private assetData;

  /// @notice Operator who can manage configuration of this contract.
  address public OPERATOR;

  /// @notice Balancer token
  IERC20Upgradeable public BAL;
  
  /// @notice Balancer Pool Token Gauge.
  IBalancerGauge public balancerGauge;

  /// @notice Balancer Token Minter
  address public balancerMinter;

  /// @notice Incentive to users who spend gas to make earmark calls to harvest BAL rewards
  uint128 public earmarkIncentive; // 100 means 1%

  /// @notice Operation fee
  uint128 public operationFee; // 1900 means 19%

  /// @notice Operation fee max
  uint128 public constant operationFeeMax = 3000;

  /// @notice Earmark incentive fee max 
  uint128 public constant earmarkIncentiveMax = 300;
  
  /// @dev Fee denominator
  uint128 public constant FEE_DENOMINATOR = 10000;

  /// @dev Deposit token that will be deposited for BAL Reward pool
  address public DEPOSIT_TOKEN_ADDR;

  /// @notice Address of BAL Reward pool
  address public BAL_REWARD_POOL;

  /* ========== EVENTS ========== */
  event FeesUpdated(uint128 _earmarkIncentive, uint128 _operationFee);
  event EmissionPerSecondUpdated(uint128 _emissionPerSecond);
  event CooldownSecondAndUnstakeWindowUpdated(uint128 _cooldownSeconds, uint128 _unstakeWindow);
  event OperatorChanged(address indexed _from, address indexed _to);
  event RewardsVaultChanged(address indexed _rewardsVault);
  event BalOperationVaultChanged(address indexed _balOperationVault);  
  event DepositTokenAndBalRewardPoolConfigured(address indexed _depositToken, address indexed _balRewardPool);
  event Staked(address indexed _user, uint256 _amount);
  event RewardsClaimedAll(address indexed _to);
  event RewardsClaimed_WNCG(address indexed _to, uint256 _amount);
  event RewardsClaimed_BAL(address indexed _to, uint256 _amount);
  event RewardsAccrued(address _user, uint256 _amount);
  event UserIndexUpdated(address indexed _user, uint256 _index);
  event AssetIndexUpdated(uint256 _index);
  event Cooldown(address indexed _user);
  event Withdrawn(address indexed _user, uint256 _amount);
  event Balancer_Gauge_Staked(address indexed _user, uint256 _amount);
  event Balancer_Gauge_Unstaked(address indexed _user, uint256 _amount);
  event BALRewardPool_Staked(address indexed _user, uint256 _amount);
  event BALRewardPool_Unstaked(address indexed _user, uint256 _amount);
  event EarmarkRewards(address indexed _user, uint256 _balReward);
 
  /* ========== INITIALIZE ========== */
  function initialize(
    IERC20Upgradeable _stakedToken,
    IERC20Upgradeable _rewardToken,
    address _operator,
    address _rewardsVault,
    address _balOperationVault,      
    IERC20Upgradeable _balToken,
    address _balancerGauge,
    address _balancerMinter
  ) external initializer {
    STAKED_TOKEN = _stakedToken;
    REWARD_TOKEN = _rewardToken;
    OPERATOR = _operator;
    REWARDS_VAULT = _rewardsVault;
    BAL_OPERATION_VAULT = _balOperationVault;    
    BAL = _balToken;
    balancerGauge = IBalancerGauge(_balancerGauge);
    balancerMinter = _balancerMinter;

    COOLDOWN_SECONDS = TWO_WEEKS;
    UNSTAKE_WINDOW = THREE_DAYS;

    assetData.emissionPerSecond = 0;
    earmarkIncentive = 100;
    operationFee = 1900; 

    // Staked Token contract that approves the Balancer Pool Gauge to transfer the staking token.
    STAKED_TOKEN.safeApprove(address(balancerGauge), type(uint256).max);
  }

  modifier onlyOperator {
    require(msg.sender == OPERATOR, 'ONLY_OPERATOR');
    _;
  }

  /**
   * @dev Config deposit token and bal reward pool
   * @param _depositToken deposit token address
   * @param _balRewardPool bal reward pool address
   */ 
  function configDepositTokenAndBalRewardPool(
    address _depositToken,
    address _balRewardPool
  ) external onlyOperator {
    DEPOSIT_TOKEN_ADDR = _depositToken;
    BAL_REWARD_POOL = _balRewardPool;
    emit DepositTokenAndBalRewardPoolConfigured(_depositToken, _balRewardPool);
  }

  /**
   * @dev Config emission per second
   * @param _emissionPerSecond rate for WNCG rewards
   */ 
  function configEmissionPerSecond(
    uint128 _emissionPerSecond
  ) external onlyOperator {
    require(_emissionPerSecond >= 0, "!emissionPerSecond");

    assetData.emissionPerSecond = _emissionPerSecond;

    emit EmissionPerSecondUpdated(_emissionPerSecond);
  }

  /**
   * @dev Config Cooldown Seconds and Unstake Window
   * @param _cooldownSeconds  Cooldown period in seconds
   * @param _unstakeWindow    Unstake(withdraw) window in seconds
   */ 
  function configCooldownSecondAndUnstakeWindow(
    uint128 _cooldownSeconds,
    uint128 _unstakeWindow
  ) external onlyOperator {
    require(_cooldownSeconds > 0, "!cooldownSeconds");
    require(_unstakeWindow > 0, "!unstakeWindow");

    COOLDOWN_SECONDS = _cooldownSeconds;
    UNSTAKE_WINDOW = _unstakeWindow;
    
    emit CooldownSecondAndUnstakeWindowUpdated(_cooldownSeconds, _unstakeWindow);
  }

  /**
   * @dev Config earmark incentive and operation fees
   * @param _earmarkIncentive Earmark incentive
   * @param _operationFee     Operation fee
   */ 
  function configFees(
    uint128 _earmarkIncentive,
    uint128 _operationFee
  ) external onlyOperator {
    require(_earmarkIncentive >= 0 && _earmarkIncentive <= earmarkIncentiveMax, "!earmarkIncentive");
    require(_operationFee >= 0 && _operationFee <= operationFeeMax, "!operationFee");

    earmarkIncentive = _earmarkIncentive;
    operationFee = _operationFee;

    emit FeesUpdated(_earmarkIncentive, _operationFee);
  }

  /**
   * @dev Change Operator
   * @param _to new opertor address
   */ 
  function changeOperator(
    address _to
  ) external onlyOperator {
    OPERATOR = _to;
    emit OperatorChanged(msg.sender, _to);
  }

  /**
   * @dev Change Rewards Vault
   * @param _rewardsVault new rewards vault
   */ 
  function changeRewardsVault(
    address _rewardsVault
  ) external onlyOperator {
    REWARDS_VAULT = _rewardsVault;
    emit RewardsVaultChanged(_rewardsVault);
  }

  /**
   * @dev Change BAL Operation Vault
   * @param _balOperationVault new BAL Operation vault
   */ 
  function changeBalOperationVault(
    address _balOperationVault
  ) external onlyOperator {
    BAL_OPERATION_VAULT = _balOperationVault;
    emit BalOperationVaultChanged(_balOperationVault);
  }

  /**
   * @dev Stake tokens, and earn rewards
   * @param _amount Amount to stake
   */  
  function stake(uint256 _amount) external {
    require(_amount != 0, 'INVALID_ZERO_AMOUNT');
    require(DEPOSIT_TOKEN_ADDR != address(0), 'INVALID_DEPOSIT_TOKEN_ADDR');
    require(BAL_REWARD_POOL != address(0), 'INVALID_BAL_REWARD_POOL');

    uint256 accruedRewards = updateUserAssetInternal(msg.sender, balances[msg.sender]);
    if (accruedRewards != 0) {
      rewardsToClaim[msg.sender] = rewardsToClaim[msg.sender].add(accruedRewards);
      emit RewardsAccrued(msg.sender, accruedRewards);
    }
    
    cooldowns[msg.sender] = getNextCooldownTimestamp(0, _amount, msg.sender, balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].add(_amount);
    totalSupply = totalSupply.add(_amount);

    // transfer staked token to this contract
    IERC20Upgradeable(STAKED_TOKEN).safeTransferFrom(msg.sender, address(this), _amount);
    emit Staked(msg.sender, _amount);
   
    // deposit token to the Balancer Gauge.
    balancerGauge.deposit(_amount);
    emit Balancer_Gauge_Staked(msg.sender, _amount);

    // stake deposit token to Bal Reward Pool, mint deposit token and stake for the user
    IDepositToken(DEPOSIT_TOKEN_ADDR).mint(address(this), _amount);
    IERC20Upgradeable(DEPOSIT_TOKEN_ADDR).safeApprove(BAL_REWARD_POOL, _amount);
    IBALRewardPool(BAL_REWARD_POOL).stakeFor(msg.sender, _amount);
    emit BALRewardPool_Staked(msg.sender, _amount);
  }

  /**
   * @dev Withdraw staked tokens, and stop earning rewards
   * @param _amount Amount to withdraw
   * @param _isClaimAllRewards if true, it claims all rewards accumulated
   */
  function withdraw(uint256 _amount, bool _isClaimAllRewards) public returns (bool) {
    require(_amount != 0, 'INVALID_ZERO_AMOUNT');
    require(DEPOSIT_TOKEN_ADDR != address(0), 'INVALID_DEPOSIT_TOKEN_ADDR');
    require(BAL_REWARD_POOL != address(0), 'INVALID_BAL_REWARD_POOL');
    
    uint256 cooldownStartTimestamp = cooldowns[msg.sender];
    uint256 cooldownEndTimestamp = cooldownStartTimestamp.add(COOLDOWN_SECONDS);
    
    require(block.timestamp > cooldownEndTimestamp, 'INSUFFICIENT_COOLDOWN');    
    require(block.timestamp.sub(cooldownEndTimestamp) <= UNSTAKE_WINDOW, 'UNSTAKE_WINDOW_FINISHED');
     
    uint256 amountToWithdraw = (_amount > balances[msg.sender]) ? balances[msg.sender] : _amount;

    updateCurrentUnclaimedRewards(msg.sender, balances[msg.sender], true);
    
    balances[msg.sender] = balances[msg.sender].sub(amountToWithdraw);
    totalSupply = totalSupply.sub(amountToWithdraw);

    if (balances[msg.sender] == 0) {
      cooldowns[msg.sender] = 0;
    }

    // withdraw for the user, burn deposit token
    IBALRewardPool(BAL_REWARD_POOL).withdrawFor(msg.sender, amountToWithdraw);
    IDepositToken(DEPOSIT_TOKEN_ADDR).burn(address(this), amountToWithdraw);
    emit BALRewardPool_Unstaked(msg.sender, amountToWithdraw);

    // unstake from the Balancer Gauge
    balancerGauge.withdraw(amountToWithdraw);
    emit Balancer_Gauge_Unstaked(address(this), amountToWithdraw); 

    // transfer staked token to the user
    IERC20Upgradeable(STAKED_TOKEN).safeTransfer(msg.sender, amountToWithdraw);
    emit Withdrawn(msg.sender, amountToWithdraw);

    // claim all rewards if true
    if(_isClaimAllRewards) {
      claimAllRewards();
    }
    
    return true;
  }

  /**
   * @dev Calculates new cooldown timestamp depending on the sender/receiver situation
   *  - If the timestamp of the sender is "better" or the timestamp of the recipient is 0, we take the one of the recipient
   *  - Weighted average of from/to cooldown timestamps if:
   *    # The sender doesn't have the cooldown activated (timestamp 0).
   *    # The sender timestamp is expired
   *    # The sender has a "worse" timestamp
   *  - If the receiver's cooldown timestamp expired (too old), the next is 0
   * @param _fromCooldownTimestamp Cooldown timestamp of the sender
   * @param _amountToReceive Amount
   * @param _toAddress Address of the recipient
   * @param _toBalance Current balance of the receiver
   * @return The new cooldown timestamp
   */
  function getNextCooldownTimestamp(
    uint256 _fromCooldownTimestamp,
    uint256 _amountToReceive,
    address _toAddress,
    uint256 _toBalance
  ) public view returns (uint256) {
    uint256 toCooldownTimestamp = cooldowns[_toAddress];
    if (toCooldownTimestamp == 0) {
      return 0;
    }

    uint256 minimalValidCooldownTimestamp = block.timestamp.sub(COOLDOWN_SECONDS).sub(UNSTAKE_WINDOW);

    if (minimalValidCooldownTimestamp > toCooldownTimestamp) {
      toCooldownTimestamp = 0;
    } else {
      uint256 timestamp = 
        (minimalValidCooldownTimestamp > _fromCooldownTimestamp)
          ? block.timestamp
          : _fromCooldownTimestamp;

      if (timestamp < toCooldownTimestamp) {
        return toCooldownTimestamp;
      } else {
        toCooldownTimestamp = (
          _amountToReceive.mul(timestamp).add(_toBalance.mul(toCooldownTimestamp))
          ).div(_amountToReceive.add(_toBalance));
      }
    }
    return toCooldownTimestamp;
  }   

  /**
   * @dev Activates the cooldown period to unstake
   * - It can't be called if the user is not staking
   */
  function cooldown() external {
    require(balances[msg.sender] != 0, 'INVALID_BALANCE_ON_COOLDOWN');    

    cooldowns[msg.sender] = block.timestamp;

    emit Cooldown(msg.sender);
  }

  /**
   * @dev Claim WNCG Rewards
   * @param _amount Amount to receive. If the amount is uint256.max vaule, receive all WNCG Rewards accumulated
   */
  function claimWNCGRewards(uint256 _amount) public {
    uint256 newTotalRewards = updateCurrentUnclaimedRewards(msg.sender, balances[msg.sender], false);
    uint256 amountToClaim = (_amount == type(uint256).max) ? newTotalRewards : _amount;
    
    rewardsToClaim[msg.sender] = newTotalRewards.sub(amountToClaim, 'INVALID_AMOUNT');
    REWARD_TOKEN.safeTransferFrom(REWARDS_VAULT, msg.sender, amountToClaim);

    emit RewardsClaimed_WNCG(msg.sender, amountToClaim);
  }

  /**
   * @dev Claim BAL Rewards (all BAL rewards from the BAL Reward Pool)
   */
  function claimBALRewards() public {
    require(BAL_REWARD_POOL != address(0), 'INVALID_BAL_REWARD_POOL');
    uint256 amountToClaim = IBALRewardPool(BAL_REWARD_POOL).earned(msg.sender);
    IBALRewardPool(BAL_REWARD_POOL).getReward(msg.sender);
    emit RewardsClaimed_BAL(msg.sender, amountToClaim);
  }

  /**
   * @dev Claim WNCG and BAL Rewards
   */
  function claimAllRewards() public {    
    claimWNCGRewards(type(uint256).max);
    claimBALRewards();
    emit RewardsClaimedAll(msg.sender);
  }

  /**
   * @dev Updates current unclaimed rewards
   * @param _user Address of the user
   * @param _userBalance The current balance of the user
   * @param _updateStorage Boolean flag used to update or not for rewardsToclaim of the user
   * @return The unclaimed rewards that were added to the total accrued
   */
  function updateCurrentUnclaimedRewards(
    address _user,
    uint256 _userBalance,
    bool _updateStorage
  ) internal returns (uint256) {
    uint256 accruedRewards = updateUserAssetInternal(_user, _userBalance);
    uint256 unclaimedRewards = rewardsToClaim[_user].add(accruedRewards);

    if (accruedRewards != 0) {
      if (_updateStorage) {
        rewardsToClaim[_user] = unclaimedRewards;
      }
      emit RewardsAccrued(_user, accruedRewards);
    }

    return unclaimedRewards;
  }

  /**
   * @dev Updates the state of an user in a distribution
   * @param _user The user's address
   * @param _stakedAmountByUser Amount of tokens staked by the user in the distribution at the moment
   * @return The accrued rewards for the user until the moment
   */
  function updateUserAssetInternal(
    address _user,
    uint256 _stakedAmountByUser
  ) internal returns (uint256) {
    uint256 userIndex = assetData.users[_user];
    uint256 accruedRewards = 0;

    uint256 newIndex = updateAssetStateInternal();

    if (userIndex != newIndex) {
      if (_stakedAmountByUser != 0) {
        accruedRewards = getRewards(_stakedAmountByUser, newIndex, userIndex);
      }

      assetData.users[_user] = newIndex;
      emit UserIndexUpdated(_user, newIndex);
    }

    return accruedRewards;
  }

  /**
   * @dev Updates the state of one distribution, mainly rewards index and timestamp
   * @return The new distribution index
   */
  function updateAssetStateInternal() internal returns (uint256) {
    uint256 oldIndex = assetData.index;
    uint128 lastUpdateTimestamp = assetData.lastUpdateTimestamp;

    if (block.timestamp == lastUpdateTimestamp) {
      return oldIndex;
    }

    uint256 newIndex = getAssetIndex(oldIndex, assetData.emissionPerSecond, lastUpdateTimestamp);

    if (newIndex != oldIndex) {
      assetData.index = newIndex;
      emit AssetIndexUpdated(newIndex);
    }

    assetData.lastUpdateTimestamp = SafeCast.toUint128(block.timestamp);

    return newIndex;
  }

  /**
   * @dev Calculates the next value of an specific distribution index, with validations
   * @param _currentIndex Current index of the distribution
   * @param _emissionPerSecond Representing the total rewards distributed per second per asset unit, on the distribution
   * @param _lastUpdateTimestamp Last moment this distribution was updated
   * @return The new index.
   */
  function getAssetIndex(
    uint256 _currentIndex,
    uint256 _emissionPerSecond,
    uint128 _lastUpdateTimestamp
  ) internal view returns (uint256) {
    uint256 currentTimestamp = block.timestamp;
    if (
      _emissionPerSecond == 0 ||
      totalSupply == 0 ||
      _lastUpdateTimestamp == currentTimestamp
    ) {
      return _currentIndex;
    }
    
    uint256 timeDelta = currentTimestamp.sub(_lastUpdateTimestamp);
    return _emissionPerSecond.mul(timeDelta).mul(10**uint256(PRECISION)).div(totalSupply).add(_currentIndex);
  }

  /**
   * @dev Internal function for the calculation of user's rewards on a distribution
   * @param _principalUserBalance Amount staked by the user on a distribution
   * @param _reserveIndex Current index of the distribution
   * @param _userIndex Index stored for the user, representation his staking moment
   * @return The rewards
   */
  function getRewards(
    uint256 _principalUserBalance,
    uint256 _reserveIndex,
    uint256 _userIndex
  ) internal pure returns (uint256) {
    return _principalUserBalance.mul(_reserveIndex.sub(_userIndex)).div(10**uint256(PRECISION));
  }

  /**
   * @dev Return the accrued rewards for an user over a list of distribution
   * @param _user The address of the user
   * @return The accrued rewards for the user until the moment
   */
  function getUnclaimedRewards(
    address _user
  ) internal view returns (uint256) {
    uint256 accruedRewards = 0;
    uint256 assetIndex = getAssetIndex(assetData.index, assetData.emissionPerSecond, assetData.lastUpdateTimestamp);
    accruedRewards = accruedRewards.add(getRewards(balances[msg.sender], assetIndex, assetData.users[_user]));
    return accruedRewards;
  }

  /**
   * @dev Earmark Rewards 
   */
  function earmarkRewards() external returns (bool){
    _earmarkRewards();
    return true;
  }
  
  /**
   * @dev Earmark Rewards, incentivise the user who spend gas to make earmark calls to harvest BAL Rewards
   *      Resposible for collecting the BAL from Gauge, and re-distributing to the correct place.
   */
  function _earmarkRewards() internal {
    require(BAL_REWARD_POOL != address(0), 'INVALID_BAL_REWARD_POOL');

    IBalancerMinter(balancerMinter).mint(address(balancerGauge));
    
    uint256 balReward = IERC20Upgradeable(BAL).balanceOf(address(this));

    if (balReward > 0) {
      // CallIncentive = caller of this contract
      uint256 _callIncentive = balReward.mul(earmarkIncentive).div(FEE_DENOMINATOR);

      // deal with operation fee
      uint256 fee = balReward.mul(operationFee).div(FEE_DENOMINATOR);
      balReward = balReward.sub(fee);

      // send oepration fee to BAL operation vault
      IERC20Upgradeable(BAL).safeTransfer(BAL_OPERATION_VAULT, fee);

      // remove incentives from balance
      balReward = balReward.sub(_callIncentive);

      // send BAL incentive to the user
      IERC20Upgradeable(BAL).safeTransfer(msg.sender, _callIncentive);

      // send BAL to BAL reward pool contract
      IERC20Upgradeable(BAL).safeTransfer(BAL_REWARD_POOL, balReward);

      // queue new rewards
      IBALRewardPool(BAL_REWARD_POOL).queueNewRewards(balReward);
    }

    emit EarmarkRewards(msg.sender, balReward);
  }

  /**
   * @dev Processes queued rewards in BAL Reward Pool
   */
  function processIdleRewards() external {
    require(BAL_REWARD_POOL != address(0), 'INVALID_BAL_REWARD_POOL');
    IBALRewardPool(BAL_REWARD_POOL).processIdleRewards();
  }

  /* ========== EXTERNAL VIEWS ========== */

  /**
   * @dev Return earned WNCG of the user
   */
  function earnedWNCG(address _user) external view returns (uint256) {
    return rewardsToClaim[_user].add(getUnclaimedRewards(_user));
  }

  /**
   * @dev Return earned BAL of the user
   */
  function earnedBAL(address _user) external view returns (uint256) {
    require(BAL_REWARD_POOL != address(0), 'INVALID_BAL_REWARD_POOL');
    return IBALRewardPool(BAL_REWARD_POOL).earned(_user);
  }

  /**
   * @dev Return total staked amount for this contact
   */
  function totalStaked() external view returns (uint256) {
    return totalSupply;
  }

  /**
   * @dev Return user's staked amount
   */
  function stakedTokenBalance(address _user) external view returns (uint256) {
    return balances[_user];
  }

  /**
   * @dev Get WNCG emission per second value
   */
  function getWNCGEmissionPerSec() external view returns (uint256) {
    return assetData.emissionPerSecond;
  }

  /**
   * @dev Get BAL Reward rate from the BAL Reward Pool
   */
  function getBALRewardRate() external view returns (uint256) {
    require(BAL_REWARD_POOL != address(0), 'INVALID_BAL_REWARD_POOL');
    return IBALRewardPool(BAL_REWARD_POOL).getRewardRate();
  }

  /**
   * @dev Get current block timestamp
   */
  function getCurrentBlockTimestamp() external view returns (uint256) {
    return block.timestamp;
  }

  /**
   * @dev Get cooldown end timestamp
   */
  function getCooldownEndTimestamp(address _user) external view returns (uint256) {    
    return cooldowns[_user].add(COOLDOWN_SECONDS);
  }

  /**
   * @dev Get withdraw end timestamp
   */
  function getWithdrawEndTimestamp(address _user) external view returns (uint256) {    
    return cooldowns[_user].add(COOLDOWN_SECONDS).add(UNSTAKE_WINDOW);
  }
}