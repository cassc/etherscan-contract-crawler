// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

library TradeConvert {
    /// @notice convert from base amount to quote amount by pip
    /// @param quantity the base amount
    /// @param pip the pip
    /// @param basisPoint the basis point to calculate amount
    /// @return quote amount
    function baseToQuote(
        uint256 quantity,
        uint128 pip,
        uint256 basisPoint
    ) internal pure returns (uint256) {
        // quantity * pip / baseBasisPoint / basisPoint / baseBasisPoint;
        // shorten => quantity * pip / basisPoint ;
        return (quantity * pip) / basisPoint;
    }

    /// @notice convert from quote amount to base amount by pip
    /// @param quoteAmount the base amount
    /// @param pip the pip
    /// @param basisPoint the basis point to calculate amount
    /// @return base amount
    function quoteToBase(
        uint256 quoteAmount,
        uint128 pip,
        uint256 basisPoint
    ) internal pure returns (uint256) {
        return (quoteAmount * basisPoint) / pip;
    }
}