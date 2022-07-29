// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOracle {
    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param token_ The address of asset
     * @return _priceInUsd The USD price
     */
    function getPriceInUsd(address token_) external view returns (uint256 _priceInUsd);

    /**
     * @notice Get quote
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     */
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut);

    /**
     * @notice Get quote in USD (or equivalent) amount
     * @param token_ The address of assetIn
     * @param amountIn_ Amount of input token.
     * @return amountOut_ Amount in USD
     */
    function quoteTokenToUsd(address token_, uint256 amountIn_) external view returns (uint256 amountOut_);

    /**
     * @notice Get quote from USD (or equivalent) amount to amount of token
     * @param token_ The address of assetOut
     * @param amountIn_ Input amount in USD
     * @return _amountOut Output amount of token
     */
    function quoteUsdToToken(address token_, uint256 amountIn_) external view returns (uint256 _amountOut);
}