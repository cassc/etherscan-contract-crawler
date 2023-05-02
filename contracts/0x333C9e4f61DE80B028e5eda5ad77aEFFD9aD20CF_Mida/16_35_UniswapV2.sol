// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "./MTMLibrary.sol";

abstract contract UniswapV2 {
  using { MTMLibrary.isEther, MTMLibrary.isStable, MTMLibrary.decimals } for address;

  function getV2TokenPrice(
    address pairAddress, uint amount
  ) public view returns(uint) {

    IUniswapV2Pair pool = IUniswapV2Pair(pairAddress);
    (uint reserves0, uint reserves1,) = pool.getReserves();

    address token; address stableOrWeth;
    uint tokenPrice;

    if(pool.token1().isEther() || pool.token1().isStable()) {

      token = pool.token0();
      stableOrWeth = pool.token1();

      tokenPrice = (reserves1 * amount) / reserves0;

    } else if(pool.token0().isEther() || pool.token0().isStable()) {

      token = pool.token1();
      stableOrWeth = pool.token0();

      tokenPrice = (reserves0 * amount) / reserves1;

    } else {
      revert("Invalid Pair");
    }

    if(stableOrWeth.isEther()) {

      // Fix the resulting number from multiplication
      uint finalDecimals;
      if(token.decimals() != 18) {
        finalDecimals = 18 - token.decimals();
      }

      tokenPrice = (ethV2Price() * tokenPrice) / (10 ** finalDecimals);

    } else {

      tokenPrice = tokenPrice * (10 ** token.decimals());

    }

    return tokenPrice;

  }

  function ethV2Price() internal view returns(uint) {
    IUniswapV2Pair pool = IUniswapV2Pair(MTMLibrary.WETH_USDT_POOL);
    (uint reserves0, uint reserves1,) = pool.getReserves();
    return (reserves1 * 1e18) / reserves0; // 1e12 is eth decimals - usdt decimals
  }

  function getV2TokenAddressFromPair(address pairAddress) internal view returns(address) {
    IUniswapV2Pair pool = IUniswapV2Pair(pairAddress);

    if(pool.token1().isEther() || pool.token1().isStable()) {
      return pool.token0();
    } else {
      return pool.token1();
    }
  }

}