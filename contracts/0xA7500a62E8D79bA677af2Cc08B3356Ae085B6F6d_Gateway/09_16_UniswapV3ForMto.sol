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
  // address private constant WETH9 = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //Goerli
  address private constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
   // mainnet
  uint24 private constant  FEE = 3000;

  
  function convertEthToExactToken(uint256 mtoAmount, address mtoToken, uint256 deadline) public payable {
    require(mtoAmount > 0, "Must pass non 0 MTO amount");
    require(msg.value > 0, "Must pass non 0 ETH amount");
      
    address tokenIn = WETH9;
    address tokenOut = mtoToken;
    address recipient = msg.sender;
    uint256 amountOut = mtoAmount;
    uint256 amountInMaximum = msg.value;
    uint160 sqrtPriceLimitX96 = 0;

    ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
        tokenIn,
        tokenOut,
        FEE,
        recipient,
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

  function getEstimatedETHforToken(address mtoToken, uint mtoAmount) external payable returns (uint256) {
    address tokenIn = WETH9;
    address tokenOut = mtoToken;
    uint24 fee = 3000;
    uint160 sqrtPriceLimitX96 = 0;

    return quoter.quoteExactOutputSingle(
        tokenIn,
        tokenOut,
        fee,
        mtoAmount,
        sqrtPriceLimitX96
    );
  }
  
  // important to receive ETH
  receive() payable external {}
}