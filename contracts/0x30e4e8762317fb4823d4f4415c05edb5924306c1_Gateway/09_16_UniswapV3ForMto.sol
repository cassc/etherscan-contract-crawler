// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

contract UniswapV3ForMto {
  IUniswapRouter public constant uniswapRouter = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Mainnet, Goerli, Arbitrum, Optimism, Polygon Address
  IQuoter public constant quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6); // Mainnet, Goerli, Arbitrum, Optimism, Polygon Address
  
  function convertEthToExactToken(address tokenIn, address tokenOut, uint256 amountOut, uint256 deadline,uint256 amountInMaximum, uint160 sqrtPriceLimitX96, uint24 fee) external payable {
    require(amountOut > 0, "Must pass non 0 MTO amount");
    require(msg.value > 0, "Must pass non 0 ETH amount");

    ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
        tokenIn,
        tokenOut,
        fee,
        msg.sender, // recipient
        deadline,
        amountOut,
        amountInMaximum,
        sqrtPriceLimitX96
    );

    uniswapRouter.exactOutputSingle{ value: msg.value }(params);
    uniswapRouter.refundETH();

    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
  }  
  // important to receive ETH
  receive() payable external {}
}