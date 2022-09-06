// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {GeneralLevSwap} from '../GeneralLevSwap.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeERC20} from '../../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {UniswapAdapter} from '../../libraries/swap/UniswapAdapter.sol';

interface ICurvePool {
  function coins(uint256) external view returns (address);

  function add_liquidity(uint256[2] memory amounts, uint256 _min_mint_amount) external;

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 _min_amount
  ) external returns (uint256);
}

contract FRAXUSDCLevSwap is GeneralLevSwap {
  using SafeERC20 for IERC20;

  ICurvePool public constant FRAXUSDC = ICurvePool(0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2);

  address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  constructor(
    address _asset,
    address _vault,
    address _provider
  ) GeneralLevSwap(_asset, _vault, _provider) {
    ENABLED_STABLE_COINS[DAI] = true;
    ENABLED_STABLE_COINS[USDC] = true;
    ENABLED_STABLE_COINS[USDT] = true;
  }

  function getAvailableStableCoins() external pure override returns (address[] memory assets) {
    assets = new address[](3);
    assets[0] = DAI;
    assets[1] = USDC;
    assets[2] = USDT;
  }

  function _swapToUSDC(address _stableAsset, uint256 _amount) internal returns (uint256) {
    UniswapAdapter.Path memory path;
    path.tokens = new address[](2);
    path.tokens[0] = _stableAsset;
    path.tokens[1] = USDC;

    path.fees = new uint256[](1);
    path.fees[0] = 500; //0.05%

    return
      UniswapAdapter.swapExactTokensForTokens(PROVIDER, _stableAsset, USDC, _amount, path, 500);
  }

  function _swapFromUSDC(address _stableAsset, uint256 _usdc_amount) internal returns (uint256) {
    UniswapAdapter.Path memory path;
    path.tokens = new address[](2);
    path.tokens[0] = USDC;
    path.tokens[1] = _stableAsset;

    path.fees = new uint256[](1);
    path.fees[0] = 500; //0.05%

    return
      UniswapAdapter.swapExactTokensForTokens(
        PROVIDER,
        USDC,
        _stableAsset,
        _usdc_amount,
        path,
        500
      );
  }

  function _swapTo(address _stableAsset, uint256 _amount) internal override returns (uint256) {
    uint256 amountTo = _amount;

    if (_stableAsset != USDC) {
      amountTo = _swapToUSDC(_stableAsset, _amount);
    }
    IERC20(USDC).safeApprove(address(FRAXUSDC), 0);
    IERC20(USDC).safeApprove(address(FRAXUSDC), amountTo);

    uint256[2] memory amountsAdded;
    amountsAdded[1] = amountTo;
    FRAXUSDC.add_liquidity(amountsAdded, 0);
    return IERC20(COLLATERAL).balanceOf(address(this));
  }

  // FRAXUSDC -> stable coin
  function _swapFrom(address _stableAsset) internal override returns (uint256) {
    int256 coinIndex = 1;
    uint256 collateralAmount = IERC20(COLLATERAL).balanceOf(address(this));
    uint256 minAmount = FRAXUSDC.calc_withdraw_one_coin(collateralAmount, int128(coinIndex));
    uint256 usdcAmount = FRAXUSDC.remove_liquidity_one_coin(
      collateralAmount,
      int128(coinIndex),
      minAmount
    );

    if (_stableAsset == USDC) {
      return usdcAmount;
    }

    return _swapFromUSDC(_stableAsset, usdcAmount);
  }
}