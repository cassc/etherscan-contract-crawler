// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmPairActions {
    /// @notice Mint liquidity for a specific position
    /// @dev Low-level function. Should be called from another contract which performs all necessary checks
    /// @param to The address to mint liquidity
    /// @param positionId The ID to store the position to allow multiple positions for a single address
    /// @return liquidity Minted liquidity
    function mint(address to, uint256 positionId)
        external
        returns (uint256 liquidity);

    /// @notice Burn liquidity from a specific position
    /// @dev Low-level function. Should be called from another contract which performs all necessary checks
    /// @param to The address to return the liquidity to
    /// @param positionId The ID of the position to burn liquidity from
    /// @param liquidity Liquidity amount to be burned
    /// @return amount0 The token0 amount received from the liquidity burn
    /// @return amount1 The token1 amount received from the liquidity burn
    function burn(
        address to,
        uint256 liquidity,
        uint256 positionId
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap tokens
    /// @dev Low-level function. Should be called from another contract which performs all necessary checks
    /// @param amount0Out token0 amount to be swapped
    /// @param amount1Out token1 amount to be swapped
    /// @param to The address to send the swapped tokens
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external;

    /// @notice Force balances to match reserves
    /// @param to The address to send excessive tokens
    function skim(address to) external;

    /// @notice Force reserves to match balances
    function sync() external;

    /// @notice Claim dividends for a specific position
    /// @param to The address to receive claimed dividends
    /// @param positionId The ID of the position to claim
    /// @return claimedAmount The amount claimed
    function claimDividend(address to, uint256 positionId)
        external
        returns (uint256 claimedAmount);
}