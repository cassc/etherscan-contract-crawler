//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IUpdateable.sol";
import "./IQuoteToken.sol";

/**
 * @title ILiquidityOracle
 * @notice An interface that defines a liquidity oracle with a single quote token (or currency) and many exchange
 *  tokens.
 */
abstract contract ILiquidityOracle is IUpdateable, IQuoteToken {
    /// @notice Gets the liquidity levels of the token and the quote token in the underlying pool.
    /// @param token The token to get liquidity levels of (along with the quote token).
    /// @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
    /// @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
    function consultLiquidity(address token)
        public
        view
        virtual
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity);

    /**
     * @notice Gets the liquidity levels of the token and the quote token in the underlying pool, reverting if the
     *  quotation is older than the maximum allowable age.
     * @dev Using maxAge of 0 can be gas costly and the returned data is easier to manipulate.
     * @param token The token to get liquidity levels of (along with the quote token).
     * @param maxAge The maximum age of the quotation, in seconds. If 0, the function gets the instant rates as of the
     *   latest block, straight from the source.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function consultLiquidity(address token, uint256 maxAge)
        public
        view
        virtual
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity);
}