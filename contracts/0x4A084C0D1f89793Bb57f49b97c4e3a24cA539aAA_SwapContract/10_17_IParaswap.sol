// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.6.0 <=0.8.9;
pragma experimental ABIEncoderV2;

import "./lib/Utils.sol";
import "./IERC20.sol";
interface IParaswap {
    function multiSwap(
        Utils.SellData calldata data
    )
        external
        payable
        returns (uint256);

    function megaSwap(
        Utils.MegaSwapSellData calldata data
    )
        external
        payable
        returns (uint256);

    function protectedMultiSwap(
        Utils.SellData calldata data
    )
        external
        payable
        returns (uint256);

    function protectedMegaSwap(
        Utils.MegaSwapSellData calldata data
    )
        external
        payable
        returns (uint256);

    function protectedSimpleSwap(
        Utils.SimpleData calldata data
    )
        external
        payable
        returns (uint256 receivedAmount);

    function protectedSimpleBuy(
        Utils.SimpleData calldata data
    )
        external
        payable;

    function simpleSwap(
        Utils.SimpleData calldata data
    )
        external
        payable
        returns (uint256 receivedAmount);

    function simpleBuy(
        Utils.SimpleData calldata data
    )
        external
        payable;

    function swapOnUniswap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        payable;

    function swapOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        payable;

    function buyOnUniswap(
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    )
        external
        payable;

    function buyOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    )
        external
        payable;

    function swapOnUniswapV2Fork(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address weth,
        uint256[] calldata pools
    )
        external
        payable;

    function buyOnUniswapV2Fork(
        address tokenIn,
        uint256 amountInMax,
        uint256 amountOut,
        address weth,
        uint256[] calldata pools
    )
        external
        payable;

    function swapOnZeroXv2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes calldata payload
    )
    external
    payable;

    function swapOnZeroXv4(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes calldata payload
    )
    external
    payable;
}