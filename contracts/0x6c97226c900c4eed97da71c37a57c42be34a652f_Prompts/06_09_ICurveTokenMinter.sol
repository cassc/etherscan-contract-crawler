pragma solidity ^0.8.13;

interface ICurveTokenMinter {
  function mint(address liquidityGauge) external;
  function minted(address user, address liquidityGauge) external returns (uint256);
}