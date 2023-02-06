// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UniswapPrice {
    using SafeMath for uint256;

    function getPrice(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        uint24 fee
    ) public view returns (uint256 price) {
        IUniswapV3Pool pool = IUniswapV3Pool(
            factory.getPool(tokenIn, tokenOut, fee)
        );
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        return
            uint256(sqrtPriceX96).mul(uint256(sqrtPriceX96)).mul(1e18) >>
            (96 * 2);
    }
}