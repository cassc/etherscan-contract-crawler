// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../external/compound/ICompoundPriceOracle.sol";

/**
 * @title ICompoundBasePriceOracle
 * @notice Returns prices of underlying tokens directly without the caller having to specify a cToken address.
 * @dev Implements the `ICompoundPriceOracle` interface.
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 */
interface ICompoundBasePriceOracle is ICompoundPriceOracle {
    /**
     * @notice Get the price of an underlying asset.
     * @param underlying The underlying asset to get the price of.
     * @return The underlying asset price in ETH as a mantissa (scaled by 1e18).
     * Zero means the price is unavailable.
     */
    function price(address underlying) external view returns (uint);
}