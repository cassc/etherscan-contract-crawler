// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMasterOracle {
    function getPriceInUsd(address token_) external view returns (uint256 _priceInUsd);

    function quote(address tokenIn_, address tokenOut_, uint256 amountIn_) external view returns (uint256 _amountOut);

    function quoteTokenToUsd(address token_, uint256 amountIn_) external view returns (uint256 amountOut_);

    function quoteUsdToToken(address token_, uint256 amountIn_) external view returns (uint256 _amountOut);
}