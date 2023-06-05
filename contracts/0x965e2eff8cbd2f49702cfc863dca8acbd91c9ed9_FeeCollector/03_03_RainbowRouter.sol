// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

/// @title Rainbow swap aggregator contract
interface RainbowRouter {

    /// @dev method to withdraw ETH (from the fees)
    /// @param to address that's receiving the ETH
    /// @param amount amount of ETH to withdraw
    function withdrawEth(
        address to, 
        uint256 amount
    ) external;

    /// @dev method to withdraw ERC20 tokens (from the fees)
    /// @param token address of the token to withdraw
    /// @param to address that's receiving the tokens
    /// @param amount amount of tokens to withdraw
    function withdrawToken(
        address token,
        address to,
        uint256 amount
    ) external;
}