// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

struct Market {
    /// @notice Whether or not this market is listed
    bool isListed;
    /**
     * @notice Multiplier representing the most one can borrow against their collateral in this market.
     *  For instance, 0.9 to allow borrowing 90% of collateral value.
     *  Must be between 0 and 1, and stored as a mantissa.
     *  The value is scaled to 18 digits:  900000000000000000
     */
    uint256 collateralFactorMantissa;
    /// @notice Whether or not this market receives XVS
    bool isVenus;
}

interface IComptroller {
    function markets(address)
        external
        view
        returns (
            bool isListed,
            uint256 collateralFactorMantissa, // scaled to 18 digits
            bool isVenus
        );

    function enterMarkets(address[] calldata vTokens)
        external
        returns (uint256[] memory);
}