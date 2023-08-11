//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "../lib/ExponentialNoError.sol";

interface ITermPriceOracle {
    function reOpenToNewBidLocker(address termAuctionBidLocker) external;

    /// @notice A function to return current market value given a token address and an amount
    /// @param token The address of the token to query
    /// @param amount The amount tokens to value
    /// @return The current market value of tokens at the specified amount, in USD
    function usdValueOfTokens(
        address token,
        uint256 amount
    ) external view returns (ExponentialNoError.Exp memory);
}