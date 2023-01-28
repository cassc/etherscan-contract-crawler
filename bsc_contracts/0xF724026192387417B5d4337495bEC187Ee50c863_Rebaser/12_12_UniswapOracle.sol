pragma solidity ^0.5.16;

import "./openzeppelin/SafeMath.sol";

contract IUniswapRouterV2 {
  function getAmountsOut(uint256 amountIn, address[] memory path) public view returns (uint256[] memory amounts);
}

contract UniswapOracle {

  using SafeMath for uint256;

  address public router; // 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
  address public usdc; //0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address public wNative;// 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  address public etf;
  address[] public path;

  constructor (address _router, address _usdc, address _wNative, address token) public {
    router = _router;
    usdc = _usdc;
    wNative = _wNative;
    etf = token;
    path = [etf, wNative, usdc];
  }

  function getPriceETF() public view returns (bool, uint256) {
    uint256[] memory amounts = IUniswapRouterV2(router).getAmountsOut(1e18, path);
    // returns the price with 6 decimals on eth and polygon mainnet, but we want 18
    // return (etf != address(0), amounts[2].mul(1e12));
    // On BSC it is 18 decimals, since USDC is 18 decimals
    return (etf != address(0), amounts[2]);
  }
}