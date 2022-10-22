/**
 * A bunch of arbitrage math utilities, some shamelessly borrowed from https://github.com/paco0x/amm-arbitrageur/ (specifically the quadratic and sqrt)
 * Some also cooked up by my insane mind
 * SPDX-License-Identifier: WTFPL
 * Licensed as per the amm-arbitrageur license, because it's really just a clone of that
 */
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

pragma solidity ^0.8.15;

library ArbUtils {
    // USDC
    address private constant _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    function calculateArbitrage(address usdcP, address wethP, address token, uint256 quote, uint256 uptwp, uint256 wptwp) internal view returns (uint256 amount, bool isUsdcLower) {
        // Turns out a "simple" arb would need to be the same pairs
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // We need to work out the "cheaper" of the two, with respect for the fact the USDC/WETH pool is needed
        {
            int256 a1;
            int256 b1;
            int256 a2;
            int256 b2;
            if(uptwp < wptwp) {
                // USDC price is under WETH price
                // Calculate a1,b2,a2,b2
                a1 = (int256) (quote);
                
                b1 = (int256) (IERC20(token).balanceOf(usdcP));
                
                a2 = (int256) (IERC20(_uniswapV2Router.WETH()).balanceOf(wethP));
                
                b2 = (int256) (IERC20(token).balanceOf(wethP));
                
                isUsdcLower = true;
            } else {
               // WETH price is under USDC price
                // Calculate a1,b2,a2,b2
                a2 = (int256) (quote);
                b2 = (int256) (IERC20(token).balanceOf(usdcP));
                a1 = (int256) (IERC20(_uniswapV2Router.WETH()).balanceOf(wethP));
                b1 = (int256) (IERC20(token).balanceOf(wethP));
                isUsdcLower = false;
            }
            // Divide a, b, and c by a big number and then multiply it back out 
            // the divisor is 9 (decimals of token) + 18 (eth decimals)
            int256 a = (a1 * b1 - a2 * b2)/(10**27);
            int256 b = (2 * b1 * b2 * (a1 + a2))/(10**27);
            int256 c = (b1 * b2 * (a1 * b2 - a2 * b1))/(10**27);
            (int256 x1,) = calcSolutionForQuadratic(a, b, c);
            // This calculates the amount required to get the two into sync - not maximum profit. 
            amount = uint256(x1) * 2;

        }

    }

    /// @dev find solution of quadratic equation: ax^2 + bx + c = 0, only return the positive solution
    function calcSolutionForQuadratic(
        int256 a,
        int256 b,
        int256 c
    ) internal pure returns (int256 x1, int256 x2) {
        int256 m = b**2 - 4 * a * c;
        // m < 0 leads to complex number
        require(m > 0, 'Complex number');

        int256 sqrtM = int256(sqrt(uint256(m)));
        x1 = (-b + sqrtM) / (2 * a);
        x2 = (-b - sqrtM) / (2 * a);
    }

    /// @dev Newton’s method for caculating square root of n
    function sqrt(uint256 n) internal pure returns (uint256 res) {
        assert(n > 1);

        // The scale factor is a crude way to turn everything into integer calcs.
        // Actually do (n * 10 ^ 4) ^ (1/2)
        uint256 _n = n * 10**6;
        uint256 c = _n;
        res = _n;

        uint256 xi;
        while (true) {
            xi = (res + c / res) / 2;
            // don't need be too precise to save gas
            if (res - xi < 1000) {
                break;
            }
            res = xi;
        }
        res = res / 10**3;
    }
}