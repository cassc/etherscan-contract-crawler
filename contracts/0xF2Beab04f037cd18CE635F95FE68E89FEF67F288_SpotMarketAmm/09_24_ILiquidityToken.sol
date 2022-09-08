//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "../external/IERC677Token.sol";

/// @title The interface for the Futureswap liquidity token that is used in IExchange.
interface ILiquidityToken is IERC677Token {
    /// @notice Mints a given amount of tokens to the exchange
    /// @param _amount The amount of tokens to mint
    function mint(uint256 _amount) external;

    /// @notice Burn a given amount of tokens from the exchange
    /// @param _amount The amount of tokens to burn
    function burn(uint256 _amount) external;
}