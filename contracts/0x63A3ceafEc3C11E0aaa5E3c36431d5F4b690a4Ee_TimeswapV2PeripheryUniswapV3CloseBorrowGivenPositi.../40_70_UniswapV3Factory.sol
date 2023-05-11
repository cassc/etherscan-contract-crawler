// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {UniswapV3PoolLibrary} from "./UniswapV3Pool.sol";

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

library UniswapV3FactoryLibrary {
  using UniswapV3PoolLibrary for address;

  function get(
    address uniswapV3Factory,
    address token0,
    address token1,
    uint24 uniswapV3Fee
  ) internal view returns (address uniswapV3Pool) {
    uniswapV3Pool = IUniswapV3Factory(uniswapV3Factory).getPool(token0, token1, uniswapV3Fee);
  }

  function getWithCheck(
    address uniswapV3Factory,
    address token0,
    address token1,
    uint24 uniswapV3Fee
  ) internal view returns (address uniswapV3Pool) {
    uniswapV3Pool = get(uniswapV3Factory, token0, token1, uniswapV3Fee);

    uniswapV3Pool.checkNotZeroAddress();
  }
}