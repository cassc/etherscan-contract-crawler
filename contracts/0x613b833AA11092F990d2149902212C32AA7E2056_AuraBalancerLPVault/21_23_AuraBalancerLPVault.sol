// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IncentiveVault} from '../../IncentiveVault.sol';
import {IERC20} from '../../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeERC20} from '../../../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {IERC20Detailed} from '../../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IConvexBooster} from '../../../../interfaces/IConvexBooster.sol';
import {IConvexBaseRewardPool} from '../../../../interfaces/IConvexBaseRewardPool.sol';
import {Errors} from '../../../libraries/helpers/Errors.sol';
import {SturdyInternalAsset} from '../../../tokenization/SturdyInternalAsset.sol';
import {PercentageMath} from '../../../libraries/math/PercentageMath.sol';
import {DataTypes} from '../../../libraries/types/DataTypes.sol';
import {ILendingPool} from '../../../../interfaces/ILendingPool.sol';

interface IRewards {
  function rewardToken() external view returns (address);

  function getReward() external;
}

/**
 * @title AuraBalancerLPVault
 * @notice Balancer LP Token Vault by using Aura on Ethereum
 * @author Sturdy
 **/
contract AuraBalancerLPVault is IncentiveVault {
  using SafeERC20 for IERC20;
  using PercentageMath for uint256;

  IConvexBooster internal constant AURA_BOOSTER =
    IConvexBooster(0xA57b8d98dAE62B26Ec3bcC4a365338157060B234);
  address internal balancerLPToken;
  address internal internalAssetToken;
  uint256 internal auraPoolId;

  uint256 internal _incentiveRatio;

  /**
   * @dev Emitted on setConfiguration()
   * @param _balancerLpToken The address of Balancer LP Token
   * @param _auraPoolId The aura pool Id
   * @param _internalToken The address of internal asset
   */
  event SetParameters(address _balancerLpToken, uint256 _auraPoolId, address _internalToken);

  /**
   * @dev Emitted on updatePoolId()
   * @param _auraPoolId The aura pool Id
   */
  event UpdatePoolId(uint256 _auraPoolId);

  /**
   * @dev The function to set parameters related to aura/balancer
   * - Caller is only PoolAdmin which is set on LendingPoolAddressesProvider contract
   * @param _lpToken The address of Balancer LP Token which will be used in vault
   * @param _poolId  The aura pool Id for Balancer LP Token
   */
  function setConfiguration(address _lpToken, uint256 _poolId) external payable onlyAdmin {
    require(_lpToken != address(0), Errors.VT_INVALID_CONFIGURATION);
    require(internalAssetToken == address(0), Errors.VT_INVALID_CONFIGURATION);

    balancerLPToken = _lpToken;
    auraPoolId = _poolId;
    SturdyInternalAsset _internalToken = new SturdyInternalAsset(
      string(abi.encodePacked('Sturdy ', IERC20Detailed(_lpToken).symbol())),
      string(abi.encodePacked('c', IERC20Detailed(_lpToken).symbol())),
      IERC20Detailed(_lpToken).decimals()
    );
    internalAssetToken = address(_internalToken);

    emit SetParameters(_lpToken, _poolId, internalAssetToken);
  }

  /**
   * @dev The function to update pool id related to aura/balancer
   * - Caller is only PoolAdmin which is set on LendingPoolAddressesProvider contract
   * @param _poolId  The aura pool Id for Balancer LP Token
   */
  function updatePoolId(uint256 _poolId) external payable onlyAdmin {
    auraPoolId = _poolId;

    emit UpdatePoolId(_poolId);
  }

  /**
   * @dev The function to get internal asset address
   * @return The address of collateral internal asset
   */
  function getInternalAsset() external view returns (address) {
    return internalAssetToken;
  }

  /**
   * @dev The function to get rewards token address
   * @return The address of rewards token
   */
  function getBaseRewardPool() internal view returns (address) {
    IConvexBooster.PoolInfo memory poolInfo = AURA_BOOSTER.poolInfo(auraPoolId);
    return poolInfo.crvRewards;
  }

  /**
   * @dev The function to send rewards to YieldManager & Treasury
   * @param _asset The rewards token address
   */
  function _transferYield(address _asset) internal {
    require(_asset != address(0), Errors.VT_PROCESS_YIELD_INVALID);
    uint256 yieldAmount = IERC20(_asset).balanceOf(address(this));

    // Some ERC20 do not allow zero amounts to be sent:
    if (yieldAmount == 0) return;

    uint256 incentiveAmount;
    uint256 fee = _incentiveRatio;
    bool isIncentiveToken = (getIncentiveToken() == _asset);
    if (isIncentiveToken && fee != 0) {
      incentiveAmount = yieldAmount.percentMul(fee);
      _sendIncentive(incentiveAmount);
    }

    // Move some yield to treasury
    fee = _vaultFee;
    if (fee != 0) {
      uint256 treasuryAmount = yieldAmount.percentMul(fee);
      IERC20(_asset).safeTransfer(_treasuryAddress, treasuryAmount);
      yieldAmount -= treasuryAmount;
    }

    if (incentiveAmount != 0) {
      yieldAmount -= incentiveAmount;
    }

    // transfer to yieldManager
    if (yieldAmount != 0) {
      address yieldManager = _addressesProvider.getAddress('YIELD_MANAGER');
      IERC20(_asset).safeTransfer(yieldManager, yieldAmount);
    }

    emit ProcessYield(_asset, yieldAmount);
  }

  /**
   * @dev Get yield based on strategy and re-deposit
   * - Caller is anyone
   */
  function processYield() external override {
    // Claim Rewards(BAL, AURA, Extra incentive tokens)
    address baseRewardPool = getBaseRewardPool();
    IConvexBaseRewardPool(baseRewardPool).getReward(address(this), false);

    // Transfer BAL to YieldManager
    _transferYield(IConvexBaseRewardPool(baseRewardPool).rewardToken());

    // Transfer AURA to YieldManager
    _transferYield(AURA_BOOSTER.minter());
  }

  /**
   * @dev The function to transfer extra incentive token to YieldManager
   * - Caller is only PoolAdmin which is set on LendingPoolAddressesProvider contract
   * @param _offset extraRewards start offset.
   * @param _count extraRewards count
   */
  function processExtraYield(uint256 _offset, uint256 _count) external payable onlyAdmin {
    address baseRewardPool = getBaseRewardPool();
    uint256 extraRewardsLength = IConvexBaseRewardPool(baseRewardPool).extraRewardsLength();

    require(_offset + _count <= extraRewardsLength, Errors.VT_EXTRA_REWARDS_INDEX_INVALID);

    for (uint256 i; i < _count; ++i) {
      address _extraReward = IConvexBaseRewardPool(baseRewardPool).extraRewards(_offset + i);
      IRewards(_extraReward).getReward();

      address _rewardToken = IRewards(_extraReward).rewardToken();
      _transferYield(_rewardToken);
    }
  }

  /**
   * @dev Get price per share based on yield strategy
   * @return The value of price per share
   */
  function pricePerShare() external view override returns (uint256) {
    uint256 decimals = IERC20Detailed(internalAssetToken).decimals();
    return 10 ** decimals;
  }

  /**
   * @dev Deposit collateral external asset to yield pool based on strategy and mint collateral internal asset
   * @param _asset The address of collateral external asset
   * @param _amount The amount of collateral external asset
   * @return The address of collateral internal asset
   * @return The amount of collateral internal asset
   */
  function _depositToYieldPool(
    address _asset,
    uint256 _amount
  ) internal override returns (address, uint256) {
    // receive Balancer LP Token from user
    address token = balancerLPToken;
    require(_asset == token, Errors.VT_COLLATERAL_DEPOSIT_INVALID);
    IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

    // deposit Balancer LP Token to Aura
    IERC20(token).safeApprove(address(AURA_BOOSTER), 0);
    IERC20(token).safeApprove(address(AURA_BOOSTER), _amount);
    require(
      AURA_BOOSTER.deposit(auraPoolId, _amount, true) == true,
      Errors.VT_COLLATERAL_DEPOSIT_INVALID
    );

    // mint
    address internalAsset = internalAssetToken;
    address lendingPoolAddress = _addressesProvider.getLendingPool();
    require(
      SturdyInternalAsset(internalAsset).mint(address(this), _amount) == true,
      Errors.VT_COLLATERAL_DEPOSIT_INVALID
    );

    // need to approve lending pool to deposit asset
    IERC20(internalAsset).safeApprove(lendingPoolAddress, 0);
    IERC20(internalAsset).safeApprove(lendingPoolAddress, _amount);

    return (internalAsset, _amount);
  }

  /**
   * @dev Get Withdrawal amount of collateral internal asset based on strategy
   * @param _asset The address of collateral external asset
   * @param _amount The withdrawal amount of collateral external asset
   * @return The address of collateral internal asset
   * @return The withdrawal amount of collateral internal asset
   */
  function _getWithdrawalAmount(
    address _asset,
    uint256 _amount
  ) internal view override returns (address, uint256) {
    require(_asset == balancerLPToken, Errors.VT_COLLATERAL_WITHDRAW_INVALID);

    // In this vault, return same amount of asset.
    return (internalAssetToken, _amount);
  }

  /**
   * @dev Burn an `_amount` of collateral internal asset and send the required collateral external asset to `_to`
   * @param _amount The amount of collateral internal asset
   * @return The amount of collateral external asset
   */
  function _withdraw(uint256 _amount, address _to) internal returns (uint256) {
    // Withdraw from Aura
    address baseRewardPool = getBaseRewardPool();
    require(
      IConvexBaseRewardPool(baseRewardPool).withdrawAndUnwrap(_amount, false) == true,
      Errors.VT_COLLATERAL_WITHDRAW_INVALID
    );

    // Deliver Balancer LP Token
    IERC20(balancerLPToken).safeTransfer(_to, _amount);

    // Burn
    SturdyInternalAsset(internalAssetToken).burn(address(this), _amount);

    return _amount;
  }

  /**
   * @dev Burn an `_amount` of collateral internal asset and send the required collateral external asset to caller on liquidation
   * - Caller is only LendingPool
   * @param _asset The address of collateral external asset
   * @param _amount The amount of collateral internal asset
   * @return The amount of collateral external asset
   */
  function withdrawOnLiquidation(
    address _asset,
    uint256 _amount
  ) external override returns (uint256) {
    require(_asset == balancerLPToken, Errors.LP_LIQUIDATION_CALL_FAILED);
    require(msg.sender == _addressesProvider.getLendingPool(), Errors.LP_LIQUIDATION_CALL_FAILED);

    return _withdraw(_amount, msg.sender);
  }

  /**
   * @dev Burn an `_amount` of collateral internal asset and deliver required collateral external asset
   * @param _asset The address of collateral external asset
   * @param _amount The withdrawal amount of collateral internal asset
   * @param _to The address of receiving collateral external asset
   * @return The amount of collateral external asset
   */
  function _withdrawFromYieldPool(
    address _asset,
    uint256 _amount,
    address _to
  ) internal override returns (uint256) {
    return _withdraw(_amount, _to);
  }

  /**
   * @dev Get the incentive token address supported on this vault
   * @return The address of incentive token
   */
  function getIncentiveToken() public view override returns (address) {
    address baseRewardPool = getBaseRewardPool();
    return IConvexBaseRewardPool(baseRewardPool).rewardToken();
  }

  /**
   * @dev Get current total incentive amount
   * @return The total amount of incentive token
   */
  function getCurrentTotalIncentiveAmount() external view override returns (uint256) {
    if (_incentiveRatio != 0) {
      address baseRewardPool = getBaseRewardPool();
      uint256 earned = IConvexBaseRewardPool(baseRewardPool).earned(address(this));
      return earned.percentMul(_incentiveRatio);
    }
    return 0;
  }

  /**
   * @dev Get Incentive Ratio
   * @return The incentive ratio value
   */
  function getIncentiveRatio() external view override returns (uint256) {
    return _incentiveRatio;
  }

  /**
   * @dev Set Incentive Ratio
   * - Caller is only PoolAdmin which is set on LendingPoolAddressesProvider contract
   */
  function setIncentiveRatio(uint256 _ratio) external override onlyAdmin {
    require(_vaultFee + _ratio < PercentageMath.PERCENTAGE_FACTOR, Errors.VT_FEE_TOO_BIG);

    // Get all available rewards & Send it to YieldDistributor,
    // so that the changing ratio does not affect asset's cumulative index
    if (_incentiveRatio != 0) {
      _clearRewards();
    }

    _incentiveRatio = _ratio;

    emit SetIncentiveRatio(_ratio);
  }

  /**
   * @dev Set treasury address and vault fee
   * - Caller is only PoolAdmin which is set on LendingPoolAddressesProvider contract
   * @param _treasury The treasury address
   * @param _fee The vault fee which has more two decimals, ex: 100% = 100_00
   */
  function setTreasuryInfo(address _treasury, uint256 _fee) public payable override onlyAdmin {
    require(_fee + _incentiveRatio < PercentageMath.PERCENTAGE_FACTOR, Errors.VT_FEE_TOO_BIG);

    super.setTreasuryInfo(_treasury, _fee);
  }

  /**
   * @dev Get AToken address for the vault
   * @return The AToken address for the vault
   */
  function _getAToken() internal view override returns (address) {
    address internalAsset = internalAssetToken;
    DataTypes.ReserveData memory reserveData = ILendingPool(_addressesProvider.getLendingPool())
      .getReserveData(internalAsset);
    return reserveData.aTokenAddress;
  }

  /**
   * @dev Claim all rewards and send some to YieldDistributor
   */
  function _clearRewards() internal override {
    address baseRewardPool = getBaseRewardPool();
    IConvexBaseRewardPool(baseRewardPool).getReward();
    _transferYield(IConvexBaseRewardPool(baseRewardPool).rewardToken());
  }
}