// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IRouteOracle {
    function resolveSwapExactTokensForTokens(
        uint256 amountIn,
        address tokenFrom,
        address tokenTo,
        address recipient
    ) external view returns ( address router, address nextToken, bytes memory sig);
}