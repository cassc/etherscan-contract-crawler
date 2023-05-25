// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ISwapper {

  function swap(
    address pool,
    address tokenIn,
    address tokenOut,
    address recipient,
    uint priceImpactTolerance
  ) external;

  function getPrice(
    address pool,
    address tokenIn,
    address tokenOut,
    uint amount
  ) external view returns (uint);

}