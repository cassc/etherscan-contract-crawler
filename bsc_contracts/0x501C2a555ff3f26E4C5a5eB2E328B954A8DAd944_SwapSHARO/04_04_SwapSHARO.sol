// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IERC20 {
  function approve(address spender, uint256 amount) external returns (bool);
}

contract SwapSHARO is Ownable {
  IUniswapV2Router02 public uniswapV2Router;

  address public immutable SHARO =
    address(0x7F3dAf301c629BfA243CbbA6654370d929379657);

  event UpdateUniswapV2Router(
    address indexed newAddress,
    address indexed oldAddress
  );

  constructor() {
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x10ED43C718714eb63d5aA57B78B54704E256024E
    );
    uniswapV2Router = _uniswapV2Router;
  }

  function swapSHAROForBNB(uint256 amountIn) external onlyOwner {
    IERC20(SHARO).approve(address(uniswapV2Router), amountIn);

    address[] memory path = new address[](2);
    path[0] = SHARO;
    path[1] = uniswapV2Router.WETH();

    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      amountIn,
      0,
      path,
      owner(),
      block.timestamp
    );
  }

  function updateUniswapV2Router(address newAddress) external onlyOwner {
    require(
      newAddress != address(uniswapV2Router),
      "SwapSHARO: The router already has that address"
    );

    emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
    uniswapV2Router = IUniswapV2Router02(newAddress);
  }
}