// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IOracleRelay.sol";
import "../../_external/uniswap/IUniswapV3PoolDerivedState.sol";
import "../../_external/uniswap/TickMath.sol";


/// @title Oracle that wraps a univ3 pool
/// @notice The oracle returns (univ3) * mul / div
/// if quote_token_is_token0 == true, then the reciprocal is returned
contract UniswapV3OracleRelay is IOracleRelay {
  bool public immutable _quoteTokenIsToken0;
  IUniswapV3PoolDerivedState public immutable _pool;
  uint32 public immutable _lookback;

  uint256 public immutable _mul;
  uint256 public immutable _div;

  /// @notice all values set at construction time
  /// @param lookback how many seconds to twap for
  /// @param  pool_address address of chainlink feed
  /// @param quote_token_is_token0 marker for which token to use as quote/base in calculation
  /// @param mul numerator of scalar
  /// @param div denominator of scalar
  constructor(
    uint32 lookback,
    address pool_address,
    bool quote_token_is_token0,
    uint256 mul,
    uint256 div
  ) {
    _lookback = lookback;
    _mul = mul;
    _div = div;
    _quoteTokenIsToken0 = quote_token_is_token0;
    _pool = IUniswapV3PoolDerivedState(pool_address);
  }

  /// @notice the current reported value of the oracle
  /// @return the current value
  /// @dev implementation in getLastSecond
  function currentValue() external view override returns (uint256) {
    return getLastSeconds(_lookback);
  }

  function getLastSeconds(uint32 seconds_) private view returns (uint256 price) {
    int56[] memory tickCumulatives;
    uint32[] memory input = new uint32[](2);
    input[0] = seconds_;
    input[1] = 0;

    (tickCumulatives, ) = _pool.observe(input);

    uint32 tickTimeDifference = seconds_;
    int56 tickCumulativeDifference = tickCumulatives[0] - tickCumulatives[1];
    bool tickNegative = tickCumulativeDifference < 0;
    uint56 tickAbs;
    if (tickNegative) {
      tickAbs = uint56(-tickCumulativeDifference);
    } else {
      tickAbs = uint56(tickCumulativeDifference);
    }

    uint56 bigTick = tickAbs / tickTimeDifference;
    require(bigTick < 887272, "Tick time diff fail");
    int24 tick;
    if (tickNegative) {
      tick = -int24(int56(bigTick));
    } else {
      tick = int24(int56(bigTick));
    }
    
    // we use 1e18 bc this is what we're going to use in exp
    // basically, you need the "price" amount of the quote in order to buy 1 base
    // or, 1 base is worth this much quote;

    price = (1e9 * ((uint256(TickMath.getSqrtRatioAtTick(tick))))) / (2**(2 * 48));

    price = price * price;

    if (!_quoteTokenIsToken0) {
      price = (1e18 * 1e18) / price;
    }

    price = (price * _mul) / _div;

  }
}