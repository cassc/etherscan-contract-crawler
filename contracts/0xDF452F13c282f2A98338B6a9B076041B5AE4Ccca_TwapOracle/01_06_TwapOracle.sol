// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ITwapOracle.sol";

import "./external/IUniswapV2Pair.sol";
import "./external/UniswapV2OracleLibrary.sol";

/// @title TwapOracle
/// @author Bluejay Core Team
/// @notice TwapOracle provides a Time-Weighted Average Price (TWAP) of a Uniswap V2 pool.
/// This is a fixed window oracle that recomputes the average price for the entire period once every period
/// https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol
contract TwapOracle is ITwapOracle {
  /// @notice Minimum period which the oracle will compute the average price
  uint256 public immutable period;

  /// @notice Address of Uniswap V2 pool address which the average price will be computed for
  IUniswapV2Pair public immutable pair;

  /// @notice Cache of token0 on the Uniswap V2 pool
  address public immutable token0;

  /// @notice Cache of token1 on the Uniswap V2 pool
  address public immutable token1;

  /// @notice Last stored cumulative price of token 0
  uint256 public price0CumulativeLast;

  /// @notice Last stored cumulative price of token 1
  uint256 public price1CumulativeLast;

  /// @notice Timestamp where cumulative prices were last fetched
  uint32 public blockTimestampLast;

  /// @notice Average price of token 0, updated on `blockTimestampLast`
  uint224 public price0Average;

  /// @notice Average price of token 1, updated on `blockTimestampLast`
  uint224 public price1Average;

  /// @notice Constructor to initialize the contract
  /// @param poolAddress Address of Uniswap V2 pool address which the average price will be computed for
  /// @param _period Minimum period which the oracle will compute the average price
  constructor(address poolAddress, uint256 _period) {
    period = _period;
    IUniswapV2Pair _pair = IUniswapV2Pair(poolAddress);
    pair = _pair;
    token0 = _pair.token0();
    token1 = _pair.token1();
    price0CumulativeLast = _pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
    price1CumulativeLast = _pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
    uint112 reserve0;
    uint112 reserve1;
    (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
    require(reserve0 != 0 && reserve1 != 0, "No liquidity in pool"); // ensure that there's liquidity in the pair
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Decode a UQ112x112 into a uint112 by truncating after the radix point
  /// https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/FixedPoint.sol
  function _decode144(uint256 num) internal pure returns (uint144) {
    return uint144(num >> 112);
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Update the average price of both tokens over the period elapsed
  /// @dev This function can only be called after the minimum period have passed since the last update
  function update() public override {
    (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
    uint32 timeElapsed = blockTimestamp - blockTimestampLast;

    require(timeElapsed >= period, "Period not elapsed");

    unchecked {
      price0Average = uint224(
        (price0Cumulative - price0CumulativeLast) / timeElapsed
      );
      price1Average = uint224(
        (price1Cumulative - price1CumulativeLast) / timeElapsed
      );
    }

    price0CumulativeLast = price0Cumulative;
    price1CumulativeLast = price1Cumulative;
    blockTimestampLast = blockTimestamp;
    emit UpdatedPrice(
      price0Average,
      price1Average,
      price0CumulativeLast,
      price1CumulativeLast
    );
  }

  /// @notice Non-reverting function to update the average prices
  function tryUpdate() public override {
    if (
      UniswapV2OracleLibrary.currentBlockTimestamp() - blockTimestampLast >=
      period
    ) {
      update();
    }
  }

  // =============================== STATIC CALL QUERY FUNCTIONS =================================

  /// @notice Non-reverting function to update the average prices and returning the prices
  /// @dev Use static call on this function to get the latest average price.
  /// Note that this will always return 0 before update has been called successfully for the first time.
  /// @param token Address of input token
  /// @param amountIn Amount of tokens input
  /// @return amountOut Amount of tokens output after the swap using the average price
  function updateAndConsult(address token, uint256 amountIn)
    public
    override
    returns (uint256 amountOut)
  {
    tryUpdate();
    return consult(token, amountIn);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Get the swap output of the token using the average price
  /// @dev Note that this will always return 0 before update has been called successfully for the first time.
  /// @param token Address of input token
  /// @param amountIn Amount of tokens input
  /// @return amountOut Amount of tokens output after the swap using the average price
  function consult(address token, uint256 amountIn)
    public
    view
    override
    returns (uint256 amountOut)
  {
    if (token == token0) {
      amountOut = _decode144(price0Average * amountIn);
    } else {
      require(token == token1, "Invalid swap");
      amountOut = _decode144(price1Average * amountIn);
    }
    require(amountOut > 0, "Zero output");
  }
}