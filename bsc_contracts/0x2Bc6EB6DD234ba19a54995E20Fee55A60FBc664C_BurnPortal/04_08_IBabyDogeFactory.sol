// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBabyDogeFactory {
  function feeTo() external view returns (address);
  function feeToTreasury() external view returns (address);
  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setRouter(address) external;

  function setFeeTo(
    address _feeTo,
    address _feeToTreasury
  ) external;

  function setFeeToSetter(address) external;
}