// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import {GeneralLevSwap} from '../GeneralLevSwap.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeERC20} from '../../../dependencies/openzeppelin/contracts/SafeERC20.sol';

interface ICurvePool {
  function coins(int128) external view returns (address);

  function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

  function add_liquidity(uint256[2] memory amounts, uint256 _min_mint_amount) external;

  function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;

  function remove_liquidity_one_coin(
    uint256 _burn_amount,
    int128 i,
    uint256 _min_received,
    address _receiver
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _burn_amount,
    int128 i,
    uint256 _min_received
  ) external;
}

contract FRAX3CRVLevSwap is GeneralLevSwap {
  using SafeERC20 for IERC20;

  ICurvePool public constant POOL = ICurvePool(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B);
  ICurvePool public constant THREECRV = ICurvePool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

  IERC20 public constant THREECRV_TOKEN = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490); // 3crv

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

  function _getCoinIndex(address _stableAsset) internal pure returns (uint256) {
    if (_stableAsset == DAI) return 0;
    if (_stableAsset == USDC) return 1;
    require(_stableAsset == USDT, 'Invalid stable coin');
    return 2;
  }

  function _swapTo(address _stableAsset, uint256 _amount) internal override returns (uint256) {
    uint256 coinIndex = _getCoinIndex(_stableAsset);

    // stable coin -> 3CRV
    IERC20(_stableAsset).safeApprove(address(THREECRV), 0);
    IERC20(_stableAsset).safeApprove(address(THREECRV), _amount);

    uint256[3] memory amountsAdded;
    amountsAdded[coinIndex] = _amount;
    THREECRV.add_liquidity(amountsAdded, 0);
    uint256 amountTo = THREECRV_TOKEN.balanceOf(address(this));

    // 3CRV -> FRAX3CRV
    THREECRV_TOKEN.safeApprove(address(POOL), 0);
    THREECRV_TOKEN.safeApprove(address(POOL), amountTo);
    POOL.add_liquidity([0, amountTo], 0);
    amountTo = IERC20(COLLATERAL).balanceOf(address(this));

    return amountTo;
  }

  function _swapFrom(address _stableAsset) internal override returns (uint256) {
    // FRAX3CRV -> 3CRV
    int256 coinIndex = 1;
    uint256 collateralAmount = IERC20(COLLATERAL).balanceOf(address(this));
    uint256 minAmount = POOL.calc_withdraw_one_coin(collateralAmount, int128(coinIndex));
    uint256 threeCRVAmount = POOL.remove_liquidity_one_coin(
      collateralAmount,
      int128(coinIndex),
      minAmount,
      address(this)
    );

    // 3CRV -> stable coin
    coinIndex = int256(_getCoinIndex(_stableAsset));
    minAmount = THREECRV.calc_withdraw_one_coin(threeCRVAmount, int128(coinIndex));

    THREECRV.remove_liquidity_one_coin(threeCRVAmount, int128(coinIndex), minAmount);

    return IERC20(_stableAsset).balanceOf(address(this));
  }
}