// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.6;

import "./CToken.sol";

interface ICompoundPriceOracle {
    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(CToken cToken) external returns (uint);
}