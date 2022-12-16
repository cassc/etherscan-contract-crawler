pragma solidity >=0.6.2;

interface ISwapFactory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function createPair(address tokenA, address tokenB) external view returns (address pair);
}