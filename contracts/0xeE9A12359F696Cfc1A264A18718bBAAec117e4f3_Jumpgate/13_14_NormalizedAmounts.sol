// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

/// @title Normalized Amounts
/// @author mymphe
/// @notice utility helper that truncates decimals of a token to prevent dust loss due to bridging decimal shift
/// @dev Wormhole Token Bridge normalizes transfer amount to 8 decimals
library NormalizedAmounts {
    /// @notice normalize token amount with more than 8 decimals
    /// @dev returns 0 if amount is too small to bridge
    /// @param amount initial token amount, e.g. 1,222,333,444,555,666,777
    /// @param decimals number of token decimals, e.g. 18
    /// @return amount normalized amount, e.g. 12,223,334,445
    function normalize(uint256 amount, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        if (decimals > 8) {
            amount /= 10**(decimals - 8);
        }
        return amount;
    }

    /// @notice denormalize token amount with more than 8 decimals
    /// @dev brings backs decimals lost after normalization as zeros
    /// @param amount normalized token amount, e.g. 12,223,334,445
    /// @param decimals number of token decimals, e.g. 18
    /// @return amount denormalized amount, e.g. 1,222,333,444,500,000,000
    function denormalize(uint256 amount, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        if (decimals > 8) {
            amount *= 10**(decimals - 8);
        }
        return amount;
    }
}