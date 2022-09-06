// SPDX-License-Identifier: MIT

/*

Coded for The Keep3r Network with ♥ by

██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

https://defi.sucks

*/

pragma solidity >=0.8.7 <0.9.0;

import './libraries/FullMath.sol';
import './libraries/TickMath.sol';
import '../interfaces/IKeep3r.sol';
import '../interfaces/IKeep3rHelper.sol';
import './Keep3rHelperParameters.sol';

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

contract Keep3rHelper is IKeep3rHelper, Keep3rHelperParameters {
  constructor(address _keep3rV2, address _governance) Keep3rHelperParameters(_keep3rV2, _governance) {}

  /// @inheritdoc IKeep3rHelper
  function quote(uint256 _eth) public view override returns (uint256 _amountOut) {
    uint32[] memory _secondsAgos = new uint32[](2);
    _secondsAgos[1] = quoteTwapTime;

    (int56[] memory _tickCumulatives, ) = IUniswapV3Pool(kp3rWethPool.poolAddress).observe(_secondsAgos);
    int56 _difference = _tickCumulatives[0] - _tickCumulatives[1];
    _amountOut = getQuoteAtTick(uint128(_eth), kp3rWethPool.isKP3RToken0 ? _difference : -_difference, quoteTwapTime);
  }

  /// @inheritdoc IKeep3rHelper
  function bonds(address _keeper) public view override returns (uint256 _amountBonded) {
    return IKeep3r(keep3rV2).bonds(_keeper, KP3R);
  }

  /// @inheritdoc IKeep3rHelper
  function getRewardAmountFor(address _keeper, uint256 _gasUsed) public view override returns (uint256 _kp3r) {
    uint256 _boost = getRewardBoostFor(bonds(_keeper));
    _kp3r = quote((_gasUsed * _boost) / BOOST_BASE);
  }

  /// @inheritdoc IKeep3rHelper
  function getRewardAmount(uint256 _gasUsed) external view override returns (uint256 _amount) {
    // solhint-disable-next-line avoid-tx-origin
    return getRewardAmountFor(tx.origin, _gasUsed);
  }

  /// @inheritdoc IKeep3rHelper
  function getRewardBoostFor(uint256 _bonds) public view override returns (uint256 _rewardBoost) {
    _bonds = Math.min(_bonds, targetBond);
    uint256 _cap = Math.max(minBoost, minBoost + ((maxBoost - minBoost) * _bonds) / targetBond);
    _rewardBoost = _cap * _getBasefee();
  }

  /// @inheritdoc IKeep3rHelper
  function getPoolTokens(address _pool) public view override returns (address _token0, address _token1) {
    return (IUniswapV3Pool(_pool).token0(), IUniswapV3Pool(_pool).token1());
  }

  /// @inheritdoc IKeep3rHelper
  function isKP3RToken0(address _pool) public view override returns (bool _isKP3RToken0) {
    address _token0;
    address _token1;
    (_token0, _token1) = getPoolTokens(_pool);
    if (_token0 == KP3R) {
      return true;
    } else if (_token1 != KP3R) {
      revert LiquidityPairInvalid();
    }
  }

  /// @inheritdoc IKeep3rHelper
  function observe(address _pool, uint32[] memory _secondsAgo)
    public
    view
    override
    returns (
      int56 _tickCumulative1,
      int56 _tickCumulative2,
      bool _success
    )
  {
    try IUniswapV3Pool(_pool).observe(_secondsAgo) returns (int56[] memory _uniswapResponse, uint160[] memory) {
      _tickCumulative1 = _uniswapResponse[0];
      if (_uniswapResponse.length > 1) {
        _tickCumulative2 = _uniswapResponse[1];
      }
      _success = true;
    } catch (bytes memory) {}
  }

  /// @inheritdoc IKeep3rHelper
  function getPaymentParams(uint256 _bonds)
    external
    view
    override
    returns (
      uint256 _boost,
      uint256 _oneEthQuote,
      uint256 _extra
    )
  {
    _oneEthQuote = quote(1 ether);
    _boost = getRewardBoostFor(_bonds);
    _extra = workExtraGas;
  }

  /// @inheritdoc IKeep3rHelper
  function getKP3RsAtTick(
    uint256 _liquidityAmount,
    int56 _tickDifference,
    uint256 _timeInterval
  ) public pure override returns (uint256 _kp3rAmount) {
    uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(int24(_tickDifference / int256(_timeInterval)));
    _kp3rAmount = FullMath.mulDiv(1 << 96, _liquidityAmount, sqrtRatioX96);
  }

  /// @inheritdoc IKeep3rHelper
  function getQuoteAtTick(
    uint128 _baseAmount,
    int56 _tickDifference,
    uint256 _timeInterval
  ) public pure override returns (uint256 _quoteAmount) {
    uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(int24(_tickDifference / int256(_timeInterval)));

    if (sqrtRatioX96 <= type(uint128).max) {
      uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
      _quoteAmount = FullMath.mulDiv(1 << 192, _baseAmount, ratioX192);
    } else {
      uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
      _quoteAmount = FullMath.mulDiv(1 << 128, _baseAmount, ratioX128);
    }
  }

  /// @notice Gets the gas basefee cost to calculate keeper rewards
  /// @dev Keepers are required to pay a priority fee to be included, this function recognizes a minimum priority fee
  /// @return _baseFee The block's basefee + a minimum priority fee, or a preset minimum gas fee
  function _getBasefee() internal view virtual returns (uint256 _baseFee) {
    return Math.max(minBaseFee, block.basefee + minPriorityFee);
  }
}