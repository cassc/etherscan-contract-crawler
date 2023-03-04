// SPDX-License-Identifier: GPL-2.0-or-later

import "./interfaces/AbstractSwapRouter.sol";
import "./utils/helpers/UniswapV2toV3.sol";
import "./utils/helpers/pancake/IPancakeFactory.sol";
import "./utils/helpers/pancake/PancakeLibrary.sol";

pragma solidity ^0.8.17;
pragma abicoder v2;

contract PancakeRouter is AbstractSwapRouter {
  using PancakeLibrary for IPancakeFactory;

  IPancakeFactory immutable factory;

  constructor(
    address _owner,
    IPancakeFactory _factory,
    IUniswapV2 _uniswapV2,
    AbstractRegistry _registry
  ) AbstractSwapRouter(_owner, new UniswapV2toV3(_uniswapV2), _registry) {
    factory = _factory;
  }

  function getAmountGivenOut(
    SwapGivenOutInput memory input
  ) external view override returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = input.tokenIn;
    path[1] = input.tokenOut;
    return factory.getAmountsOut(input.amountOut, path)[0];
  }

  function getAmountGivenIn(
    SwapGivenInInput memory input
  ) external view override returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = input.tokenIn;
    path[1] = input.tokenOut;
    return factory.getAmountsIn(input.amountIn, path)[0];
  }
}