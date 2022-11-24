// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract SwapSHARO is Ownable {
  IUniswapV2Router02 public uniswapV2Router;

  address public immutable SHARO =
    address(0x7F3dAf301c629BfA243CbbA6654370d929379657);
  address public immutable BUSD =
    address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

  constructor() {
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x10ED43C718714eb63d5aA57B78B54704E256024E
    );
    uniswapV2Router = _uniswapV2Router;
  }

  function swapSHAROForBNB(uint256 tokenAmount) public onlyOwner {
    address[] memory path = new address[](3);
    path[0] = SHARO;
    path[1] = uniswapV2Router.WETH();

    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      owner(),
      block.timestamp
    );
  }

  function swapSHAROForBUSD(uint256 tokenAmount) public onlyOwner {
    address[] memory path = new address[](3);
    path[0] = SHARO;
    path[1] = uniswapV2Router.WETH();
    path[2] = BUSD;

    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      owner(),
      block.timestamp
    );
  }
}