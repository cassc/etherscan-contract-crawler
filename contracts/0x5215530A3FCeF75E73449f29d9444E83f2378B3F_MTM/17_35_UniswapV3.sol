// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "./FullMath.sol";
import "./TickMath.sol";
import "./MTMLibrary.sol";

abstract contract UniswapV3 {
  using { MTMLibrary.isEther, MTMLibrary.isStable, MTMLibrary.decimals } for address;

  uint private constant Q96 = 2**96;

  function getV3TokenPrice(
    address pairAddress, uint amount
  ) internal view returns(uint) {

    IUniswapV3Pool pool = IUniswapV3Pool(pairAddress);
    uint poolPriceX96 = getPriceX96FromSqrtPriceX96(getSqrtTwapX96(pairAddress));

    address token; address stableOrWeth;
    uint tokenPrice;

    if(pool.token1().isEther() || pool.token1().isStable()) {

      token = pool.token0();
      stableOrWeth = pool.token1();

      tokenPrice = ((amount * poolPriceX96) / Q96);

    } else if(pool.token0().isEther() || pool.token0().isStable()) {

      token = pool.token1();
      stableOrWeth = pool.token0();

      tokenPrice = ((amount * Q96) / poolPriceX96);

    } else {
      revert("Invalid Pair");
    }

    // If this is a eth pool, get the price of eth && multiply it by this price
    if(stableOrWeth.isEther()) {

      // Fix the resulting number from multiplication
      uint finalDecimals;
      if(token.decimals() != 18) {
        finalDecimals = 18 - token.decimals();
      }

      if(address(token) == address(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8)) {

        // For some reason, xen decimals are wack?
        tokenPrice = (etherV3Price() * tokenPrice) * (10 ** 10);

      } else {

        tokenPrice = (etherV3Price() * tokenPrice) / (10 ** finalDecimals);

      }

    } else {

      tokenPrice = tokenPrice * (10 ** token.decimals());

    }

    return tokenPrice;
  }

  function etherV3Price() internal view returns(uint) {
    uint ethPriceX96 = getPriceX96FromSqrtPriceX96(getSqrtTwapX96(MTMLibrary.WETH_USDC_POOL));
    return ( ( 1e18 * (2**96) ) / ethPriceX96 );
  }

  function getV3TokenAddressFromPair(address pairAddress) internal view returns(address) {
    IUniswapV3Pool pool = IUniswapV3Pool(pairAddress);

    if(pool.token1().isEther() || pool.token1().isStable()) {
      return pool.token0();
    } else {
      return pool.token1();
    }
  }

  /// @dev Fetches time weighted price square root (scaled 2 ** 96) from a uniswap v3 pool.
  /// @param uniswapV3Pool Address of the uniswap v3 pool.
  /// @return sqrtPriceX96 Time weighted square root token price (scaled 2 ** 96).
  function getSqrtTwapX96(address uniswapV3Pool) internal view returns (uint160 sqrtPriceX96) {
    uint32[] memory secondsAgos = new uint32[](2);
    secondsAgos[0] = MTMLibrary.TWAP_INTERVAL;
    secondsAgos[1] = 0;

    (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

    sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
      int24((tickCumulatives[1] - tickCumulatives[0]) / int8(MTMLibrary.TWAP_INTERVAL))
    );

    return sqrtPriceX96;
  }

  /// @dev Converts a uniswap v3 square root price into a token price (scaled 2 ** 96).
  /// @param sqrtPriceX96 Square root uniswap pool price (scaled 2 ** 96).
  /// @return priceX96 Token price (scaled 2 ** 96).
  function getPriceX96FromSqrtPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256 priceX96) {
      return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
  }

}