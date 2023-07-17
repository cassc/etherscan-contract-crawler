// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20Metadata.sol";

library TokenPriceCalculator {
    //Returns the price of a given token that has 18 decimals in USDC, to 6 decimal places.
    function calculateTokenPriceInUSDC(address tokenAddress, address pairAddress) public view returns (uint256) {
        IUniswapV2Pair usdcPair;

        if(block.chainid == 56) {
            usdcPair = IUniswapV2Pair(0xd99c7F6C65857AC913a8f880A4cb84032AB2FC5b);
        }
        else {
            usdcPair = IUniswapV2Pair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);
        }


        (uint256 usdcReseres, uint256 wethReserves,) = usdcPair.getReserves();

        //in 6 decimals
        uint256 usdcPerEth = usdcReseres * 1e18 / wethReserves;

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        (uint256 r0, uint256 r1,) = pair.getReserves();

        IERC20Metadata token0 = IERC20Metadata(pair.token0());
        IERC20Metadata token1 = IERC20Metadata(pair.token1());

        address weth = usdcPair.token1();

        if(address(token1) == tokenAddress) {
            IERC20Metadata tokenTemp = token0;
            token0 = token1;
            token1 = tokenTemp;

            uint256 rTemp = r0;
            r0 = r1;
            r1 = rTemp;
        }

        require(address(token1) == weth);

        return r1 * 1e18 / r0 * usdcPerEth / 1e18;
    }
}