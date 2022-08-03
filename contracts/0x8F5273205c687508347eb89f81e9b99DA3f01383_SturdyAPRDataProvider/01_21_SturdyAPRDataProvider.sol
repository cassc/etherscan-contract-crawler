// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IPriceOracle} from '../interfaces/IPriceOracle.sol';
import {ILidoOracle} from '../interfaces/ILidoOracle.sol';
import {ILido} from '../interfaces/ILido.sol';
import {IConvexBooster} from '../interfaces/IConvexBooster.sol';
import {IProtocolDataProvider} from '../interfaces/IProtocolDataProvider.sol';
import {ICurvePool} from '../interfaces/ICurvePool.sol';
import {IConvexBaseRewardPool} from '../interfaces/IConvexBaseRewardPool.sol';
import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {ICollateralAdapter} from '../interfaces/ICollateralAdapter.sol';
import {IIncentiveVault} from '../interfaces/IIncentiveVault.sol';
import {IGeneralVault} from '../interfaces/IGeneralVault.sol';
import {ILendingPool} from '../interfaces/ILendingPool.sol';
import {PercentageMath} from '../protocol/libraries/math/PercentageMath.sol';
import {ReserveConfiguration} from '../protocol/libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';

contract SturdyAPRDataProvider is Ownable {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  struct ConvexPoolInfo {
    uint256 poolId;
    address poolAddress;
  }

  IProtocolDataProvider private constant DATA_PROVIDER =
    IProtocolDataProvider(0x960993Cb6bA0E8244007a57544A55bDdb52db97e);
  address private constant LIDO = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
  address private constant LIDO_ORACLE = 0x442af784A788A5bd6F42A01Ebe9F287a871243fb;
  address private constant CONVEX_BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
  address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
  address private constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
  address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  uint256 private STURDY_FEE = 10_00;
  uint256 private constant CVX_CLIFF_SIZE = 1e23; // new cliff every 100,000 tokens
  uint256 private constant CVX_CLIFF_COUNT = 1000; //1,000 cliffs
  uint256 private constant CVX_MAX_SUPPLY = 1e26; //100 mil max supply

  IPriceOracle private immutable ORACLE;
  ICollateralAdapter private immutable COLLATERAL_ADAPTER;
  ILendingPool private immutable LENDING_POOL;

  // convex reserve's internal asset -> convex pool info
  mapping(address => ConvexPoolInfo) internal convexReserves;

  constructor() public {
    ORACLE = IPriceOracle(DATA_PROVIDER.ADDRESSES_PROVIDER().getPriceOracle());
    COLLATERAL_ADAPTER = ICollateralAdapter(
      DATA_PROVIDER.ADDRESSES_PROVIDER().getAddress('COLLATERAL_ADAPTER')
    );
    LENDING_POOL = ILendingPool(DATA_PROVIDER.ADDRESSES_PROVIDER().getLendingPool());
  }

  function registerConvexReserve(
    address _reserve,
    uint256 _poolId,
    address _poolAddress
  ) external payable onlyOwner {
    convexReserves[_reserve] = ConvexPoolInfo(_poolId, _poolAddress);
  }

  /**
   * @dev Get APR with wad decimal(=18)
   */
  function APR(address _borrowReserve) external view returns (uint256) {
    address[] memory reserves = LENDING_POOL.getReservesList();
    uint256 reserveCount = reserves.length;
    uint256 totalYieldInPrice;
    uint256 totalBorrowableLiquidityInPrice = _getTotalLiquidity(DAI, true) +
      _getTotalLiquidity(USDC, true) +
      _getTotalLiquidity(USDT, true);

    for (uint256 i; i < reserveCount; ++i) {
      DataTypes.ReserveConfigurationMap memory reserveConfiguration = LENDING_POOL.getConfiguration(
        reserves[i]
      );
      (, , , , bool isCollateral) = reserveConfiguration.getFlagsMemory();
      if (!isCollateral) continue;

      if (reserves[i] == LIDO) {
        totalYieldInPrice += _lidoVaultYieldInPrice();
      } else {
        totalYieldInPrice += _convexVaultYieldInPrice(reserves[i]);
      }
    }

    uint256 totalVaultAPR = totalYieldInPrice / totalBorrowableLiquidityInPrice;
    uint256 liquidityRate = uint256(
      LENDING_POOL.getReserveData(_borrowReserve).currentLiquidityRate
    ) / 1e9; // dividing by 1e9 to pass from ray to wad

    return totalVaultAPR + liquidityRate;
  }

  /**
   * @dev Get vault APR with wad decimal(=18)
   * @param _reserve - vault's internal asset address
   */
  function vaultReserveAPR(address _reserve) external view returns (uint256) {
    uint256 totalBorrowableLiquidityInPrice = _getTotalLiquidity(DAI, true) +
      _getTotalLiquidity(USDC, true) +
      _getTotalLiquidity(USDT, true);

    if (_reserve == LIDO) {
      return _lidoVaultYieldInPrice() / totalBorrowableLiquidityInPrice;
    }

    return _convexVaultYieldInPrice(_reserve) / totalBorrowableLiquidityInPrice;
  }

  /**
   * @dev Get lidoVault Yield per year with wad decimal(=18)
   */
  function _lidoVaultYieldInPrice() internal view returns (uint256) {
    uint256 stETHCollateralInPrice = _getTotalLiquidity(LIDO, true);
    uint256 stETHYieldInPrice = (_lidoAPR() * stETHCollateralInPrice).percentMul(
      PercentageMath.PERCENTAGE_FACTOR - STURDY_FEE
    );

    return stETHYieldInPrice;
  }

  /**
   * @dev Get convexVault Yield per year with wad decimal(=18)
   * @param _reserve - convex vault's internal asset address
   */
  function _convexVaultYieldInPrice(address _reserve) internal view returns (uint256) {
    ConvexPoolInfo memory reserveInfo = convexReserves[_reserve];
    if (reserveInfo.poolAddress == address(0)) {
      return _fallbackVaultYieldInPrice(_reserve);
    }

    IConvexBooster.PoolInfo memory poolInfo = IConvexBooster(CONVEX_BOOSTER).poolInfo(
      reserveInfo.poolId
    );
    // lptoken is external asset of convex vault
    address vault = COLLATERAL_ADAPTER.getAcceptableVault(poolInfo.lptoken);
    uint256 incentiveFee = IIncentiveVault(vault).getIncentiveRatio();

    uint256 convexLPCollateral = _getTotalLiquidity(_reserve, false);
    uint8 decimals = IERC20Detailed(_reserve).decimals();
    (uint256 crvAPYInPrice, uint256 cvxAPYInPrice) = _convexCRVCVXAPYInPrice(
      poolInfo.crvRewards,
      reserveInfo.poolAddress
    );
    uint256 convexLPYieldInPrice = ((crvAPYInPrice.percentMul(
      PercentageMath.PERCENTAGE_FACTOR - STURDY_FEE - incentiveFee
    ) + cvxAPYInPrice.percentMul(PercentageMath.PERCENTAGE_FACTOR - STURDY_FEE)) *
      convexLPCollateral) / 10**decimals;

    return convexLPYieldInPrice * 1e18;
  }

  /**
   * @dev Get other vault Yield per year with wad decimal(=18)
   * @param _reserve - vault's internal asset address
   */
  function _fallbackVaultYieldInPrice(address _reserve) internal view returns (uint256) {
    address externalAsset = COLLATERAL_ADAPTER.getExternalCollateralAsset(_reserve);
    IGeneralVault vault = IGeneralVault(COLLATERAL_ADAPTER.getAcceptableVault(externalAsset));
    return vault.vaultYieldInPrice();
  }

  /**
   * @dev APR percent value with wad decimal(=18)
   */
  function _lidoAPR() internal view returns (uint256) {
    (uint256 postTotalPooledEther, uint256 preTotalPooledEther, uint256 timeElapsed) = ILidoOracle(
      LIDO_ORACLE
    ).getLastCompletedReportDelta();
    uint256 lidoFee = uint256(ILido(LIDO).getFee());
    uint256 protocolAPR = ((postTotalPooledEther - preTotalPooledEther) * 365 days * 1e18) /
      (preTotalPooledEther * timeElapsed);

    return protocolAPR.percentMul(PercentageMath.PERCENTAGE_FACTOR - lidoFee);
  }

  /**
   * @dev CRV/CVX APY in price
   * @param _stakeContract - convex LP pool's crvRewards address
   * @param _poolAddress - convex LP pool address
   */
  function _convexCRVCVXAPYInPrice(address _stakeContract, address _poolAddress)
    internal
    view
    returns (uint256, uint256)
  {
    uint256 virtualPrice = ICurvePool(_poolAddress).get_virtual_price(); //decimal 18
    uint256 rate = IConvexBaseRewardPool(_stakeContract).rewardRate(); //decimal 18
    uint256 supply = IConvexBaseRewardPool(_stakeContract).totalSupply(); //decimal 18

    // crvPerUnderlying = rate / ((supply / 1e18) * (virtualPrice / 1e18))
    uint256 crvPerUnderlying = (rate * 1e36) / (supply * virtualPrice);
    uint256 crvPerYear = crvPerUnderlying * 365 days;
    uint256 cvxPerYear = _getCVXMintAmount(crvPerYear);
    return (
      (crvPerYear * ORACLE.getAssetPrice(CRV)) / 1e18,
      (cvxPerYear * ORACLE.getAssetPrice(CVX)) / 1e18
    ); //crv/cvx decimal 18
  }

  function _getTotalLiquidity(address _asset, bool _inPrice)
    internal
    view
    returns (uint256 totalLiquidity)
  {
    uint8 decimals = IERC20Detailed(_asset).decimals();
    (
      uint256 availbleLiquidity,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      ,
      ,
      ,
      ,
      ,
      ,

    ) = DATA_PROVIDER.getReserveData(_asset);
    totalLiquidity = (totalLiquidity + availbleLiquidity + totalStableDebt + totalVariableDebt);
    if (_inPrice) {
      totalLiquidity = (totalLiquidity * ORACLE.getAssetPrice(_asset)) / 10**decimals;
    }
  }

  function _getCVXMintAmount(uint256 _crvEarned) internal view returns (uint256) {
    //first get total supply
    uint256 cvxSupply = IERC20(CVX).totalSupply();

    //get current cliff
    uint256 currentCliff = cvxSupply / CVX_CLIFF_SIZE;
    if (currentCliff < CVX_CLIFF_COUNT) {
      //get remaining cliffs
      uint256 remaining = CVX_CLIFF_COUNT - currentCliff;

      //multiply ratio of remaining cliffs to total cliffs against amount CRV received
      uint256 cvxEarned = (_crvEarned * remaining) / CVX_CLIFF_COUNT;

      //double check we have not gone over the max supply
      uint256 amountTillMax = CVX_MAX_SUPPLY - cvxSupply;
      if (cvxEarned > amountTillMax) {
        cvxEarned = amountTillMax;
      }

      return cvxEarned;
    }

    return 0;
  }
}