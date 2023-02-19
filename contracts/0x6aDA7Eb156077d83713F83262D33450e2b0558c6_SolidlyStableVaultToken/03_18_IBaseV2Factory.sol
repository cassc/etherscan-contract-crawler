pragma solidity >=0.5.0;

interface IBaseV2Factory {
  function poolFees(address pool) external view returns (uint256);
}