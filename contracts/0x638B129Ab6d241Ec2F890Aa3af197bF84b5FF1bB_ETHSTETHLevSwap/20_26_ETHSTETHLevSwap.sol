// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {GeneralLevSwap} from '../GeneralLevSwap.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeERC20} from '../../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {IWETH} from '../../../misc/interfaces/IWETH.sol';
import {PercentageMath} from '../../libraries/math/PercentageMath.sol';
import {Errors} from '../../libraries/helpers/Errors.sol';

interface ICurvePool {
  function coins(uint256) external view returns (address);

  function add_liquidity(uint256[2] memory amounts, uint256 _min_mint_amount) external payable;

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 _min_amount
  ) external returns (uint256);
}

contract ETHSTETHLevSwap is GeneralLevSwap {
  using SafeERC20 for IERC20;
  using PercentageMath for uint256;

  ICurvePool public constant ETHSTETH = ICurvePool(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

  address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Receive ETH
   */
  receive() external payable {}

  constructor(
    address _asset,
    address _vault,
    address _provider
  ) GeneralLevSwap(_asset, _vault, _provider) {
    ENABLED_BORROWING_ASSET[WETH] = true;
  }

  function getAvailableBorrowingAssets() external pure override returns (address[] memory assets) {
    assets = new address[](1);
    assets[0] = WETH;
  }

  /// borrowing asset -> ETHSTETH
  function _swapTo(
    address _borrowingAsset,
    uint256 _amount,
    uint256 _slippage
  ) internal override returns (uint256) {
    require(_borrowingAsset == WETH, Errors.LS_INVALID_CONFIGURATION);

    // WETH -> ETH
    IWETH(WETH).withdraw(_amount);

    uint256[2] memory amountsAdded;
    amountsAdded[0] = _amount;
    ETHSTETH.add_liquidity{value: _amount}(amountsAdded, 0);
    uint256 collateralAmount = IERC20(COLLATERAL).balanceOf(address(this));
    require(
      collateralAmount >= _getMinAmount(_amount, _slippage, 1e18, _getAssetPrice(COLLATERAL)),
      Errors.LS_SUPPLY_NOT_ALLOWED
    );

    return collateralAmount;
  }

  /// ETHSTETH -> borrowing asset
  function _swapFrom(address _borrowingAsset, uint256 _slippage)
    internal
    override
    returns (uint256)
  {
    require(_borrowingAsset == WETH, Errors.LS_INVALID_CONFIGURATION);

    uint256 collateralAmount = IERC20(COLLATERAL).balanceOf(address(this));
    uint256 minAmount = ETHSTETH.calc_withdraw_one_coin(collateralAmount, 0);
    require(
      minAmount >= _getMinAmount(collateralAmount, _slippage, _getAssetPrice(COLLATERAL), 1e18),
      Errors.LS_SUPPLY_NOT_ALLOWED
    );

    uint256 ethAmount = ETHSTETH.remove_liquidity_one_coin(collateralAmount, 0, minAmount);

    // ETH -> WETH
    IWETH(WETH).deposit{value: ethAmount}();

    return ethAmount;
  }

  function _getMinAmount(
    uint256 _amountToSwap,
    uint256 _slippage,
    uint256 _fromAssetPrice,
    uint256 _toAssetPrice
  ) internal view returns (uint256) {
    return
      ((_amountToSwap * _fromAssetPrice) / _toAssetPrice).percentMul(
        PercentageMath.PERCENTAGE_FACTOR - _slippage
      );
  }
}