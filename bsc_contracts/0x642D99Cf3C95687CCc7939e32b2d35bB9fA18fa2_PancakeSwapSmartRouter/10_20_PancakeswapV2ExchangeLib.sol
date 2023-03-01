// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IPancakeswapV2Factory.sol";
import "../interfaces/IPancakeswapV2Exchange.sol";
import "./UniERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

library PancakeswapV2ExchangeLib {
    using Math for uint256;
    using UniERC20 for IERC20;

    function getReturn(
        IPancakeswapV2Exchange exchange,
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amountIn
    )
    internal
    view
    returns (
        uint256 result,
        bool needSync
    )
    {
        uint256 reserveIn = srcToken.uniBalanceOf(address(exchange));
        uint256 reserveOut = dstToken.uniBalanceOf(address(exchange));
        (uint112 reserve0, uint112 reserve1, ) = exchange.getReserves();
        if (srcToken > dstToken) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        amountIn = reserveIn - reserve0;
        needSync = (reserveIn < reserve0 || reserveOut < reserve1);

        uint256 amountInWithFee = amountIn * 9975;
        uint256 numerator = amountInWithFee * Math.min(reserveOut, reserve1);
        uint256 denominator = Math.min(reserveIn, reserve0) * 10000 + amountInWithFee;
        result = (denominator == 0) ? 0 : numerator / denominator;
    }
}