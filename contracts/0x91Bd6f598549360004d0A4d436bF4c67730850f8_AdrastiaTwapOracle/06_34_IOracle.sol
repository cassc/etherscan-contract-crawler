//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IUpdateable.sol";
import "./ILiquidityOracle.sol";
import "./IPriceOracle.sol";

/**
 * @title IOracle
 * @notice An interface that defines a price and liquidity oracle.
 */
abstract contract IOracle is IUpdateable, IPriceOracle, ILiquidityOracle {
    /// @notice Emitted when a stored quotation is updated.
    /// @param token The address of the token that the quotation is for.
    /// @param price The quote token denominated price for a whole token.
    /// @param tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
    /// @param quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
    /// @param timestamp The epoch timestamp of the quotation (in seconds).
    event Updated(
        address indexed token,
        uint256 price,
        uint256 tokenLiquidity,
        uint256 quoteTokenLiquidity,
        uint256 timestamp
    );

    /**
     * @notice Gets the price of a token in terms of the quote token along with the liquidity levels of the token
     *  andquote token in the underlying pool.
     * @param token The token to get the price of.
     * @return price The quote token denominated price for a whole token.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function consult(address token)
        public
        view
        virtual
        returns (
            uint112 price,
            uint112 tokenLiquidity,
            uint112 quoteTokenLiquidity
        );

    /**
     * @notice Gets the price of a token in terms of the quote token along with the liquidity levels of the token and
     *  quote token in the underlying pool, reverting if the quotation is older than the maximum allowable age.
     * @dev Using maxAge of 0 can be gas costly and the returned data is easier to manipulate.
     * @param token The token to get the price of.
     * @param maxAge The maximum age of the quotation, in seconds. If 0, the function gets the instant rates as of the
     *   latest block, straight from the source.
     * @return price The quote token denominated price for a whole token.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function consult(address token, uint256 maxAge)
        public
        view
        virtual
        returns (
            uint112 price,
            uint112 tokenLiquidity,
            uint112 quoteTokenLiquidity
        );
}