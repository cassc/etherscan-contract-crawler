// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {UniswapV3FactoryLibrary} from "./UniswapV3Factory.sol";

library Verify {
  error CanOnlyBeCalledByUniswapV3Contract();

  function uniswapV3Pool(address uniswapV3Factory, address token0, address token1, uint24 uniswapV3Fee) internal view {
    address pool = UniswapV3FactoryLibrary.get(uniswapV3Factory, token0, token1, uniswapV3Fee);

    if (pool != msg.sender) revert CanOnlyBeCalledByUniswapV3Contract();
  }
}