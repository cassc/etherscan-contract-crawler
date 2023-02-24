// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;
import "./IMToken.sol";

interface IPriceOracle {
    /**
     * @notice Get the underlying price of a mToken asset
     * @param mToken The mToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     *
     * @dev Price should be scaled to 1e18 for tokens with tokenDecimals = 1e18
     *      and for 1e30 for tokens with tokenDecimals = 1e6.
     */
    function getUnderlyingPrice(IMToken mToken) external view returns (uint256);

    /**
     * @notice Return price for an asset
     * @param asset address of token
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     * @dev Price should be scaled to 1e18 for tokens with tokenDecimals = 1e18
     *      and for 1e30 for tokens with tokenDecimals = 1e6.
     */
    function getAssetPrice(address asset) external view returns (uint256);
}