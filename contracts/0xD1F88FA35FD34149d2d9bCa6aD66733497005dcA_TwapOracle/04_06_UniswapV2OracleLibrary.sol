// SPDX-License-Identifier: GPL-3.0-or-later
// https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/FixedPoint.sol
pragma solidity ^0.8.4;

import "./IUniswapV2Pair.sol";

// References
// https://github.com/fei-protocol/fei-protocol-core/blob/develop/contracts/external/UniswapV2OracleLibrary.sol
// https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/FullMath.sol
// https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1

library FullMath {
  uint256 constant MAX_256 = type(uint256).max;

  function fullMul(uint256 x, uint256 y)
    internal
    pure
    returns (uint256 l, uint256 h)
  {
    uint256 mm = mulmod(x, y, MAX_256);
    l = x * y;
    h = mm - l;
    if (mm < l) h -= 1;
  }

  function fullDiv(
    uint256 l,
    uint256 h,
    uint256 d
  ) private pure returns (uint256) {
    uint256 pow2 = uint256(int256(d) & -int256(d));
    d /= pow2;
    l /= pow2;
    l += h * (uint256((-int256(pow2)) / int256(pow2 + 1)));
    uint256 r = 1;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    return l * r;
  }

  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 d
  ) internal pure returns (uint256) {
    (uint256 l, uint256 h) = fullMul(x, y);

    uint256 mm = mulmod(x, y, d);
    if (mm > l) h -= 1;
    l -= mm;

    if (h == 0) return l / d;

    require(h < d, "FullMath: FULLDIV_OVERFLOW");
    return fullDiv(l, h, d);
  }
}

library FixedPoint {
  // range: [0, 2**112 - 1]
  // resolution: 1 / 2**112
  struct uq112x112 {
    uint224 _x;
  }

  uint8 public constant RESOLUTION = 112;
  uint256 public constant Q112 = 2**112;
  uint144 constant MAX_144 = type(uint144).max;
  uint224 constant MAX_224 = type(uint224).max;

  // returns a UQ112x112 which represents the ratio of the numerator to the denominator
  // can be lossy
  function fraction(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(denominator > 0, "FixedPoint::fraction: division by zero");
    if (numerator == 0) return FixedPoint.uq112x112(0);

    if (numerator <= MAX_144) {
      uint256 result = (numerator << RESOLUTION) / denominator;
      require(result <= MAX_224, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    } else {
      uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
      require(result <= MAX_224, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    }
  }
}

library UniswapV2OracleLibrary {
  using FixedPoint for *;

  // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
  function currentBlockTimestamp() internal view returns (uint32) {
    return uint32(block.timestamp % 2**32);
  }

  // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
  function currentCumulativePrices(address pair)
    internal
    view
    returns (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    )
  {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
    price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    if (blockTimestampLast != blockTimestamp) {
      unchecked {
        // subtraction overflow is desired
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        // addition overflow is desired
        price0Cumulative +=
          uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
          timeElapsed;
        price1Cumulative +=
          uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
          timeElapsed;
      }
    }
  }
}