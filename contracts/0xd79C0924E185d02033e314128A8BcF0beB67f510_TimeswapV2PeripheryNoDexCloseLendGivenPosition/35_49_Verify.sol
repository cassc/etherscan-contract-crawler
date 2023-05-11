// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2OptionFactory} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2OptionFactory.sol";

import {ITimeswapV2PoolFactory} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2PoolFactory.sol";

library Verify {
  error CanOnlyBeCalledByOptionContract();

  error CanOnlyBeCalledByPoolContract();

  error CanOnlyBeCalledByTokensContract();

  error CanOnlyBeCalledByLiquidityTokensContract();

  function timeswapV2Option(address optionFactory, address token0, address token1) internal view {
    address optionPair = ITimeswapV2OptionFactory(optionFactory).get(token0, token1);

    if (optionPair != msg.sender) revert CanOnlyBeCalledByOptionContract();
  }

  function timeswapV2Pool(
    address optionFactory,
    address poolFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair) {
    optionPair = ITimeswapV2OptionFactory(optionFactory).get(token0, token1);

    address poolPair = ITimeswapV2PoolFactory(poolFactory).get(optionPair);

    if (poolPair != msg.sender) revert CanOnlyBeCalledByPoolContract();
  }

  function timeswapV2Token(address tokens) internal view {
    if (tokens != msg.sender) revert CanOnlyBeCalledByTokensContract();
  }

  function timeswapV2LiquidityToken(address liquidityTokens) internal view {
    if (liquidityTokens != msg.sender) revert CanOnlyBeCalledByLiquidityTokensContract();
  }
}