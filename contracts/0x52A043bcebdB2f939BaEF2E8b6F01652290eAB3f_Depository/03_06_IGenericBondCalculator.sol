// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev Interface for generic bond calculator.
interface IGenericBondCalculator {
    /// @dev Calculates the amount of OLAS tokens based on the bonding calculator mechanism.
    /// @param tokenAmount LP token amount.
    /// @param priceLP LP token price.
    /// @return amountOLAS Resulting amount of OLAS tokens.
    function calculatePayoutOLAS(uint256 tokenAmount, uint256 priceLP) external view
        returns (uint256 amountOLAS);

    /// @dev Get reserveX/reserveY at the time of product creation.
    /// @param token Token address.
    /// @return priceLP Resulting reserve ratio.
    function getCurrentPriceLP(address token) external view returns (uint256 priceLP);
}