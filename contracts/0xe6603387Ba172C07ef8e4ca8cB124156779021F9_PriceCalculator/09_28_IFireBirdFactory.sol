// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IFireBirdFactory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint32 tokenWeight0, uint32 swapFee, uint);

  function feeTo() external view returns (address);

  function formula() external view returns (address);

  function protocolFee() external view returns (uint);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB, uint32 tokenWeightA, uint32 swapFee) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function isPair(address) external view returns (bool);

  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB, uint32 tokenWeightA, uint32 swapFee) external returns (address pair);

  function getWeightsAndSwapFee(address pair) external view returns (uint32 tokenWeight0, uint32 tokenWeight1, uint32 swapFee);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;

  function setProtocolFee(uint) external;
}