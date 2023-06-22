pragma solidity 0.6.6;

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
interface IBtcPriceOracle {
  // note this will always return 0 before update has been called successfully for the first time.
  function consult(uint256 amountIn) external view returns (uint256 amountOut);
}