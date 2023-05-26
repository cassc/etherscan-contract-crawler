pragma solidity 0.5.17;

// Compound finance's price oracle
interface PriceOracle {
  // returns the price of the underlying token in USD, scaled by 10**(36 - underlyingPrecision)
  function getUnderlyingPrice(address cToken) external view returns (uint);
}