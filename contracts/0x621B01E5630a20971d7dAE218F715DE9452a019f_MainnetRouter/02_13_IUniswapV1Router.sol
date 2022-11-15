// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IUniswapV1Router {
    function tokenToEthTransferInput(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address to
    ) external returns (uint256 amountOut);

    function ethToTokenTransferInput(
        uint256 amountOutMin,
        uint256 deadline,
        address to
    ) external payable returns (uint256 amountOut);

    function tokenToTokenTransferInput(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 minETHOut,
        uint256 deadline,
        address recipient,
        address tokenAddress
    )
        external
        payable
        returns (uint256 amountOut);
}