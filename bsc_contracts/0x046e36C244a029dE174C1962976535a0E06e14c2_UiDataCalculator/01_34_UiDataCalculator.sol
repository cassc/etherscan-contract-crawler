// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from '../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {ILendingPoolAddressesProvider} from '../interfaces/ILendingPoolAddressesProvider.sol';
import {IAaveIncentivesController} from '../interfaces/IAaveIncentivesController.sol';
import {ILendingPool} from '../interfaces/ILendingPool.sol';
import {IPriceOracleGetter} from '../interfaces/IPriceOracleGetter.sol';
import {IAToken} from '../interfaces/IAToken.sol';
import {WadRayMath} from '../protocol/libraries/math/WadRayMath.sol';
import {ReserveConfiguration} from '../protocol/libraries/configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../protocol/libraries/configuration/UserConfiguration.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {DefaultReserveInterestRateStrategy} from '../protocol/lendingpool/DefaultReserveInterestRateStrategy.sol';
import {ReserveLogic} from '../protocol/libraries/logic/ReserveLogic.sol';
import {ChefIncentivesController} from '../staking/ChefIncentivesController.sol';
import {MasterChef} from '../staking/MasterChef.sol';

interface IUniswapLPToken {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract UiDataCalculator {
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using ReserveLogic for DataTypes.ReserveData;

    uint256 constant SECONDS_PER_YEAR = 31536000;
    uint256 constant RAY = 1e27;

    address immutable weth;

    IPriceOracleGetter public immutable oracle;

    constructor(IPriceOracleGetter _oracle, address _weth) {
      oracle = _oracle;
      weth = _weth;
    }

    function rewardPrice(address pair) public view returns (uint256) {
        return _rewardPrice(pair);
    }

    function getReservesList(ILendingPoolAddressesProvider provider)
      public
      view
      returns (address[] memory)
    {
      ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
      return lendingPool.getReservesList();
    }

    function getReservesData(ILendingPoolAddressesProvider provider, address asset)
      public
      view
      returns (DataTypes.ReserveData memory)
    {
      ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
      DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(asset);
      return reserveData;
    }

    function calculateApr(ILendingPoolAddressesProvider provider, address asset)
      public
      view
      returns (uint256, uint256)
    {
      ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
      DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(asset);

      uint256 depositAPR = reserveData.currentLiquidityRate/1e7; // x 1e18 /RAY x100
      uint256 variableBorrowAPR = reserveData.currentVariableBorrowRate/1e7;

      return (depositAPR,variableBorrowAPR);
    }

    function calculateAprIncentive(ILendingPoolAddressesProvider provider, address incentiveController, address asset, address pair)
      public
      view
      returns (uint256, uint256)
    {
      ChefIncentivesController incentive = ChefIncentivesController(incentiveController);
      ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
      DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(asset);
      uint256 fetchPriceAsset = oracle.getAssetPrice(asset);
      uint256 price = _rewardPrice(pair);
      uint256 rewardPerSec = incentive.rewardsPerSecond();
      address varDebtToken = reserveData.variableDebtTokenAddress;
      address aToken = reserveData.aTokenAddress;

      (uint256 varSupply, uint256 allocVar,,,) = incentive.poolInfo(varDebtToken);
      (uint256 aTokenSupply, uint256 allocAToken,,,) = incentive.poolInfo(aToken);

      uint256 apyVarDebtToken =
        (rewardPerSec*SECONDS_PER_YEAR*allocVar*price/incentive.totalAllocPoint()).div((varSupply*fetchPriceAsset)/10**IERC20Detailed(varDebtToken).decimals());
      uint256 apyAToken =
        (rewardPerSec*SECONDS_PER_YEAR*allocAToken*price/incentive.totalAllocPoint()).div((aTokenSupply*fetchPriceAsset)/10**IERC20Detailed(varDebtToken).decimals());

      return (apyAToken*100,apyVarDebtToken*100);
    }

    function _fetchPriceETH() internal view returns (uint256) {
        uint256 fetchPrice = oracle.getAssetPrice(weth);
        return fetchPrice;
    }

    function _getTokenPrice(address pairAddress) internal view returns(uint256)
    {
      IUniswapLPToken pair = IUniswapLPToken(pairAddress);
      // (uint256 Res0, uint256 Res1,) = pair.getReserves();
      (uint256 r0, uint256 r1, ) = pair.getReserves();
      (uint256 bnbReserve, uint256 sculptReserve) = pair.token0() == weth ? (r0, r1) : (r1, r0);

      // decimals
      uint256 res0 = bnbReserve*(10**18);
      return(res0/sculptReserve); // return amount of token1 needed to buy token0
    }

    function _rewardPrice(address pair) internal view returns (uint256) {
        uint256 tokenAmount = _getTokenPrice(pair);
        uint256 rewardPrice = (tokenAmount*_fetchPriceETH())/1e18;

        return rewardPrice;
    }
}